codeunit 50100 "SWC-HAR003Send Invoice"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, CODEUNIT::"Purch.-Post", 'OnAfterFinalizePosting', '', false, false)]
    local procedure OnAfterSalesPost(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PreviewMode: Boolean)
    begin
        if not PreviewMode then begin
            if PurchInvHeader."No." <> '' then
                SendInvoice(PurchInvHeader);

            if PurchCrMemoHdr."No." <> '' then
                SentCreditMemo(PurchCrMemoHdr);
        end;

    end;

    procedure SendInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        SMTPSetup: Record "SMTP Mail Setup";
        ReportSelections: Record "Report Selections";
        PurchInvHeaderRef: RecordRef;
        SMTPMail: Codeunit "SMTP Mail";
        BlobStorage: Codeunit "Temp Blob";
        EmailOutStream: OutStream;
        EmailInStream: InStream;
        Recipients: List of [Text];
        BodyText: Text;
    begin
        PurchasePayablesSetup.Get();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Invoice");
        if PurchasePayablesSetup."Enable Invoice Email" and ReportSelections.Find('-') then begin
            SMTPSetup.Get();
            PurchasePayablesSetup.TestField("Invoice Email Recipients");

            BlobStorage.CreateOutStream(EmailOutStream);
            BlobStorage.CreateInStream(EmailInStream);

            PurchInvHeaderRef.GetTable(PurchInvHeader);
            PurchInvHeaderRef.SetRecFilter();
            Report.SaveAs(ReportSelections."Report ID", '', ReportFormat::Pdf, EmailOutStream, PurchInvHeaderRef);

            Recipients.Add(PurchasePayablesSetup."Invoice Email Recipients");
            BodyText := StrSubstNo('Purchase Invoice %1 for Vendor %2', PurchInvHeader."No.", PurchInvHeader."Pay-to Vendor No.");
            SMTPMail.CreateMessage('', SMTPSetup."User ID", Recipients, StrSubstNo('Purchase Invoice %1', PurchInvHeader."No."), BodyText);
            SMTPMail.AddAttachmentStream(EmailInStream, StrSubstNo('Purchase Invoice %1.pdf', PurchInvHeader."No."));
            SMTPMail.Send();
        end;
    end;

    procedure SentCreditMemo(CreditMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        SMTPSetup: Record "SMTP Mail Setup";
        ReportSelections: Record "Report Selections";
        TempBlob: Record TempBlob temporary;
        PurchCrMemoHeaderRef: RecordRef;
        SMTPMail: Codeunit "SMTP Mail";
        EmailOutStream: OutStream;
        EmailInStream: InStream;
        BodyText: Text;
        Recipients: List of [Text];
    begin
        PurchasePayablesSetup.Get();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Cr.Memo");
        if PurchasePayablesSetup."Enable Invoice Email" and ReportSelections.Find('-') then begin
            SMTPSetup.Get();
            PurchasePayablesSetup.TestField("Invoice Email Recipients");

            TempBlob.Blob.CreateOutStream(EmailOutStream, TextEncoding::UTF8);
            TempBlob.Blob.CreateInStream(EmailInStream, TextEncoding::UTF8);

            PurchCrMemoHeaderRef.GetTable(CreditMemoHeader);
            PurchCrMemoHeaderRef.SetRecFilter();
            Report.SaveAs(ReportSelections."Report ID", '', ReportFormat::Pdf, EmailOutStream, PurchCrMemoHeaderRef);

            Recipients.Add(PurchasePayablesSetup."Invoice Email Recipients");
            BodyText := StrSubstNo('Purchase Credit Memo %1 for Vendor %2', CreditMemoHeader."No.", CreditMemoHeader."Pay-to Vendor No.");
            SMTPMail.CreateMessage('', SMTPSetup."User ID", Recipients, StrSubstNo('Purchase Credit Memo %1', CreditMemoHeader."No."), BodyText);
            SMTPMail.AddAttachmentStream(EmailInStream, StrSubstNo('Purchase Invoice %1.pdf', CreditMemoHeader."No."));
            SMTPMail.Send();
        end;
    end;
}