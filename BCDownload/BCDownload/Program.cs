using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Runtime.InteropServices;

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

            // Get the last entry number
            JObject jSettings = new JObject();
            jSettings = JObject.Load(JValue.Parse(File.ReadAllText(SettingsFile)).CreateReader());
            int LastEntry = Convert.ToInt32(jSettings["Entry_No"]);

            // Azure AD registrations:
            // Specifies the Azure AD tenant ID
            string AadTenantId = Properties.Settings.Default.AadTenantId;
            // Specifies the Application (client) ID of the console application registration in Azure AD
            string ClientId = Properties.Settings.Default.ClientId;
            // Specifies the redirect URL for the client that was configured for console application registration in Azure AD
            string ClientRedirectUrl = Properties.Settings.Default.ClientRedirectUrl;
            // Specifies the APP ID URI that is configured for the registered Business Central application in Azure AD
            string ServerAppIdUri = Properties.Settings.Default.ServerAppIdUri;

            string EndPoint = Properties.Settings.Default.BCURL;            
            string DestinationFolder = Properties.Settings.Default.DestinationFolder;
            string DestinationFile = Properties.Settings.Default.DestinationFile;
            string ArchiveFolder = Properties.Settings.Default.ArchiveFolder;
            string AdditionalFilter = Properties.Settings.Default.PageFilter;

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

            // Create the output file
            StreamWriter fs = new StreamWriter(FullDestinationFile, false, Encoding.ASCII);

            // Read the data
            string Header = "\"Date\",\"Reference\",\"Account\",\"Debit\",\"Credit\"";

            try
            {                
                AuthenticationResult authenticationResult;
                AuthenticationContext authenticationContext = new AuthenticationContext("https://login.microsoftonline.com/" + AadTenantId, new FileTokenCache(ProgramDataFolder + "\\BCDownload\\TokenCache.dat"));
                if (authenticationContext.TokenCache.Count != 0)
                    authenticationResult = authenticationContext.AcquireTokenAsync(ServerAppIdUri, ClientId, new Uri(ClientRedirectUrl), new PlatformParameters(PromptBehavior.Never)).GetAwaiter().GetResult();
                else
                    authenticationResult = authenticationContext.AcquireTokenAsync(ServerAppIdUri, ClientId, new Uri(ClientRedirectUrl), new PlatformParameters(PromptBehavior.SelectAccount)).GetAwaiter().GetResult();

                // Connect to the Business Central OData web service
                var nav = new NAV.NAV(new Uri(EndPoint));
                nav.BuildingRequest += (sender, eventArgs) => eventArgs.Headers.Add("Authorization", authenticationResult.CreateAuthorizationHeader());

                // Retrieve and return a list of the customers 
                string filterString = String.Format("Entry_No%20gt%20{0}", LastEntry);
                if (AdditionalFilter.Length > 0)
                    filterString = string.Format("{0}%20and%20{1}", filterString, System.Web.HttpUtility.UrlPathEncode(AdditionalFilter));

                Microsoft.OData.Client.DataServiceQuery<NAV.General_Ledger_Export> qx = nav.General_Ledger_Export.AddQueryOption("$filter", filterString);
                foreach (NAV.General_Ledger_Export glExport in qx.GetAllPages())
                {
                    if (Header.Length > 0)
                    {
                        fs.WriteLine(Header);
                        Header = "";
                    }
                    fs.WriteLine(String.Format("\"{0}\",\"{1}\",\"{2}\",{3:########0.00},{4:########0.00}",
                        glExport.Posting_Date, glExport.Document_No, glExport.G_L_Account_No, glExport.Debit_Amount, glExport.Credit_Amount));
                    LastEntry = glExport.Entry_No;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("The following error occurred: {0}", ex.Message);
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
