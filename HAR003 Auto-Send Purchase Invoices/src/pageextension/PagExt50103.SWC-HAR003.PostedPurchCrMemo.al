pageextension 50103 "SWC-HAR003 PostedPurchCrMemo" extends "Posted Purchase Credit Memo"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Print")
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
                    SendInvoice.SentCreditMemo(Rec);
                    Message('The credit memo has been sent.');
                end;
            }
        }
    }
}