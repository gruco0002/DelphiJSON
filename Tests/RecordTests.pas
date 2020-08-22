unit RecordTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TRecordTests = class(TObject)
  public

    [Test]
    procedure SerializationTest;

  end;

implementation

uses
  DelphiJSON, System.JSON, JSONComparer;

type

  [DJSerializable]
  TTestRec = record

  [DJValue('text')]
    data: string;

    [DJValue('int')]
    number: integer;

    [DJValue('bool')]
    statement: boolean;
  end;

  { TRecordTests }

procedure TRecordTests.SerializationTest;
const
  res = '{"text":"abc", "int":42, "bool":true}';
var
  tmp: TTestRec;
  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := 'abc';
  tmp.number := 42;
  tmp.statement := true;

  ser := DelphiJSON<TTestRec>.SerializeJ(tmp);

  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TRecordTests);

end.
