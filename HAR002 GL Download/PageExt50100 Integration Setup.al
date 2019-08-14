pageextension 50100 "G/L Integration Setup" extends "General Ledger Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Show Amounts")
        {
            field("Integration Filter"; "Integration Filter Preview")
            {
                ApplicationArea = All, Basic;
                AssistEdit = true;

                trigger OnAssistEdit()
                begin
                    EditIntegrationFilter();
                end;
            }
        }
    }
}