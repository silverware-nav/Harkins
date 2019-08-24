codeunit 50100 "SWC-HAR003Send Invoice"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, CODEUNIT::"Purch.-Post", 'OnAfterFinalizePosting', '', false, false)]
    local procedure OnAfterSalesPost(var PurchInvHeader: Record "Purch. Inv. Header"; PreviewMode: Boolean)
    begin
        if not PreviewMode and (PurchInvHeader."No." <> '') then
            SendInvoice(PurchInvHeader);
    end;

    procedure SendInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        SMTPSetup: Record "SMTP Mail Setup";
        ReportSelections: Record "Report Selections";
        TempBlob: Record TempBlob temporary;
        PurchInvHeaderRef: RecordRef;
        SMTPMail: Codeunit "SMTP Mail";
        EmailOutStream: OutStream;
        EmailInStream: InStream;
        BodyText: Text;
    begin
        PurchasePayablesSetup.Get();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Invoice");
        if PurchasePayablesSetup."Enable Invoice Email" and ReportSelections.Find('-') then begin
            SMTPSetup.Get();
            PurchasePayablesSetup.TestField("Invoice Email Recipients");

            TempBlob.Blob.CreateOutStream(EmailOutStream, TextEncoding::UTF8);
            TempBlob.Blob.CreateInStream(EmailInStream, TextEncoding::UTF8);

            PurchInvHeaderRef.GetTable(PurchInvHeader);
            PurchInvHeaderRef.SetRecFilter();
            Report.SaveAs(ReportSelections."Report ID", '', ReportFormat::Pdf, EmailOutStream, PurchInvHeaderRef);

            BodyText := StrSubstNo('Purchase Invoice %1 for Vendor %2', PurchInvHeader."No.", PurchInvHeader."Pay-to Vendor No.");
            SMTPMail.CreateMessage('', SMTPSetup."User ID", PurchasePayablesSetup."Invoice Email Recipients", StrSubstNo('Purchase Invoice %1', PurchInvHeader."No."), BodyText, true);
            SMTPMail.AddAttachmentStream(EmailInStream, StrSubstNo('Purchase Invoice %1.pdf', PurchInvHeader."No."));
            SMTPMail.Send();
        end;
    end;
}