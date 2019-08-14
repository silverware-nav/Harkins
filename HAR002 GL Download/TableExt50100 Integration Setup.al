tableextension 50100 "G/L Integration Setup" extends "General Ledger Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50100; "Integration Filter Preview"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50102; "Integration Filter"; Blob)
        {
            DataClassification = CustomerContent;
        }
    }

    procedure EditIntegrationFilter()
    var
        GLEntry: Record "G/L Entry";
        DynamicRequestFields: Record "Dynamic Request Page Field";
        FilterPage: FilterPageBuilder;
        IStr: InStream;
        OStr: OutStream;
        FilterText: Text;
        RecRef: RecordRef;
        FldRef: FieldRef;
        FieldFilterText: Text;
    begin
        CalcFields("Integration Filter");
        "Integration Filter".CreateInStream(IStr);
        IStr.ReadText(FilterText);

        if (FilterText <> '') then
            GLEntry.SetView(FilterText);
        FilterPage.AddRecord(GLEntry.TableName(), GLEntry);
        RecRef.GetTable(GLEntry);

        DynamicRequestFields.SetRange("Table ID", DATABASE::"G/L Entry");
        if DynamicRequestFields.FindSet() then
            repeat
                FldRef := RecRef.Field(DynamicRequestFields."Field ID");
                FieldFilterText := FldRef.GetFilter();
                FilterPage.AddFieldNo(GLEntry.TableName(), DynamicRequestFields."Field ID", FieldFilterText);
            until DynamicRequestFields.Next() = 0;

        if FilterPage.RunModal() then begin
            clear("Integration Filter");
            FilterText := FilterPage.GetView(GLEntry.TableName());
            "Integration Filter".CreateOutStream(OStr);
            OStr.WriteText(FilterText);
            GLEntry.SetView(FilterText);
            "Integration Filter Preview" := CopyStr(GLEntry.GetFilters(), 1, MaxStrLen("Integration Filter Preview"));
            Modify();
        end;
    end;

    procedure GetIntegrationFilter() FilterText: Text
    var
        IStr: InStream;
    begin
        CalcFields("Integration Filter");
        "Integration Filter".CreateInStream(IStr);
        IStr.ReadText(FilterText);
    end;
}