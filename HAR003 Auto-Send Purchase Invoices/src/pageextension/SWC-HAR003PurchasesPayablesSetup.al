pageextension 50101 "SWC-HAR003PurchasesPayables" extends "Purchases & Payables Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter(General)
        {
            group(Email)
            {
                Caption = 'Email';

                field("Enable Invoice Email"; "Enable Invoice Email")
                {
                    ApplicationArea = All;
                }
                field("Invoice Email Recipients"; "Invoice Email Recipients")
                {
                    ApplicationArea = All;
                }
            }
        }

    }
}