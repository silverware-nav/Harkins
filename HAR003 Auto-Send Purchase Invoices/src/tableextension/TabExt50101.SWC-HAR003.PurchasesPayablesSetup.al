tableextension 50101 "SWC-HAR003PurchasesPayables" extends "Purchases & Payables Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50100; "Enable Invoice Email"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(50102; "Invoice Email Recipients"; Text[200])
        {
            DataClassification = CustomerContent;
        }
    }

}