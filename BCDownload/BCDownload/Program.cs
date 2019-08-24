using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;

namespace BCDownload
{
    class Program
    {
        static void Main(string[] args)
        {
            string SettingsFile;

            // Create the ProgramData folder if needed
            string ProgramDataFolder = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            if (!Directory.Exists(ProgramDataFolder + "\\BCDownload"))
            {
                Console.Write("ProgramData setting folder does not exist. Creating it...");
                Directory.CreateDirectory(ProgramDataFolder + "\\BCDownload");
            }

            SettingsFile = ProgramDataFolder + "\\BCDownload\\download.json";
            if (!File.Exists(SettingsFile))
                File.WriteAllText(SettingsFile, "{\r\n  \"Entry_No\": 0\r\n}");

            string EndPoint = Properties.Settings.Default.BCURL;            
            string UserName = Properties.Settings.Default.UserName;
            string Password = Properties.Settings.Default.Password;
            string DestinationFolder = Properties.Settings.Default.DestinationFolder;
            string DestinationFile = Properties.Settings.Default.DestinationFile;
            string ArchiveFolder = Properties.Settings.Default.ArchiveFolder;

            // First, move the current file if one exists
            string FullDestinationFile = Path.Combine(DestinationFolder, DestinationFile);
            string ArchiveFileName = Path.Combine(ArchiveFolder, ArchiveName(DestinationFile));
            if (File.Exists(FullDestinationFile))
            {
                if (File.Exists(ArchiveFileName))
                    //File.Delete(ArchiveFileName);
                    throw new Exception(string.Format("Archive file {0} already exists", ArchiveFileName));
                File.Move(FullDestinationFile, ArchiveFileName);
            }

            // Get the last entry number
            JObject jSettings = new JObject();
            jSettings = JObject.Load(JValue.Parse(File.ReadAllText(SettingsFile)).CreateReader());
            int LastEntry = Convert.ToInt32(jSettings["Entry_No"]);

            // Create the output file
            StreamWriter fs = new StreamWriter(FullDestinationFile, false, Encoding.ASCII);

            // Read the data
            string Header = "\"Date\",\"Reference\",\"Account\",\"Debit\",\"Credit\"";
            bool MoreData = true;
            while (MoreData)
            {
                MoreData = false;

                try
                {
                    Uri uri = new Uri(String.Format("{0}?$filter=Entry_No%20gt%20{1}", EndPoint, LastEntry));
                    HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(uri);
                    request.Method = "GET";
                    string Credentials = Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes(String.Format("{0}:{1}", UserName, Password)));
                    request.Headers.Add("Authorization", "Basic " + Credentials);
                    request.PreAuthenticate = true;                    

                    request.Accept = "application/json";
                    WebResponse response = request.GetResponse();
                    StreamReader responseReader = new StreamReader(response.GetResponseStream());
                    string responseString = responseReader.ReadToEnd();

                    // Parse the data
                    JObject jData = new JObject();
                    jData = JObject.Load(JValue.Parse(responseString).CreateReader());

                    JArray jArray = JArray.Parse(jData["value"].ToString());
                    if (jArray.Count > 0)
                    {
                        if (Header.Length > 0)
                        {
                            fs.Write(Header);
                            Header = "";
                        }

                        MoreData = true;
                        foreach (JObject jElement in jArray)
                        {
                            int EntryNo = Convert.ToInt32(jElement["Entry_No"]);
                            if (EntryNo > LastEntry)
                                LastEntry = EntryNo;

                            fs.WriteLine(String.Format("\"{0}\",\"{1}\",\"{2}\",{3:########0.00},{4:########0.00}",
                                jElement.GetValue("Posting_Date"),
                                jElement.GetValue("Document_No"),
                                jElement.GetValue("G_L_Account_No"),
                                jElement.GetValue("Debit_Amount"),
                                jElement.GetValue("Credit_Amount")
                                ));
                        }
                    }
                    
                }
                catch (System.Net.WebException ex)
                {
                    Console.WriteLine("WebException Raised.  The following error occurred: {0}", ex.Message);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("The following error occurred: {0}", ex.Message);
                }
            }

            fs.Close();
            if (Convert.ToInt32(jSettings["Entry_No"]) < LastEntry)
            {
                jSettings["Entry_No"] = LastEntry;
                File.WriteAllText(SettingsFile, jSettings.ToString(Formatting.Indented));
            }
            else
                File.Delete(FullDestinationFile);
        }

        static string ArchiveName(string TemplateName)
        {
            string ArchiveFileName = String.Format("{0}{1}{2}", Path.GetFileNameWithoutExtension(TemplateName), DateTime.Now.ToString("yyyyMMdd"), Path.GetExtension(TemplateName));
            return ArchiveFileName;
        }
    }
}
