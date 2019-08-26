pageextension 50102 "SWC-HAR003PostedPurchaseInv" extends "Posted Purchase Invoice"
{
    actions
    {
        // Add changes to page actions here
        addafter(Print)
        {
            action(Send)
            {
                ApplicationArea = All;
                Caption = 'Email to A/R';
                Promoted = true;
                PromotedCategory = Category6;
                Image = Email;
                ToolTip = 'Send to Company A/R Department';

                trigger OnAction()
                var
                    SendInvoice: Codeunit "SWC-HAR003Send Invoice";
                begin
                    SendInvoice.SendInvoice(Rec);
                    Message('The invoice has been sent.');
                end;
            }
        }
    }
}