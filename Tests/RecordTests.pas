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

    [Test]
    procedure DeserializeTest;

    [Test]
    procedure SerializeManagedRecord;

    [Test]
    procedure DeserializeManagedRecord;

  end;

implementation

uses
  DelphiJSON, System.JSON, JSONComparer, System.DateUtils, System.SysUtils;

type

  [DJSerializable]
  TTestRec = record
  public
    [DJValue('text')]
    data: string;

    [DJValue('int')]
    number: integer;

    [DJValue('bool')]
    statement: boolean;

    [DJValue('dt')]
    dt: TDateTime;
  end;

  [DJSerializable]
  TManagedRecord = record
  public
    [DJValue('text')]
    data: string;

    [DJValue('int')]
    number: integer;

    [DJValue('bool')]
    statement: boolean;

    [DJValue('dt')]
    dt: TDateTime;

    numberThatShouldGetInitialized: integer;

    class operator Initialize(out dest: TManagedRecord);

  end;

  {TRecordTests}

procedure TRecordTests.DeserializeManagedRecord;
const
  res = '{"text":"abc", "int":42, "bool":true, "dt":"2012-05-23T18:25:43.123Z"}';
var
  tmp: TManagedRecord;
begin
  tmp.data := 'absdfgfc';
  tmp.number := 4245;
  tmp.statement := false;
  tmp.dt := Now;

  tmp := DelphiJSON<TManagedRecord>.Deserialize(res);

  Assert.AreEqual('abc', tmp.data);
  Assert.AreEqual(42, tmp.number);
  Assert.AreEqual(true, tmp.statement);
  Assert.AreEqual(EncodeDateTime(2012, 05, 23, 18, 25, 43, 123), tmp.dt);

  // check that the record was initialized correctly
  Assert.AreEqual(45684211, tmp.numberThatShouldGetInitialized);

end;

procedure TRecordTests.DeserializeTest;
const
  res = '{"text":"abc", "int":42, "bool":true, "dt":"2012-05-23T18:25:43.123Z"}';
var
  tmp: TTestRec;
begin
  tmp.data := 'absdfgfc';
  tmp.number := 4245;
  tmp.statement := false;
  tmp.dt := Now;

  tmp := DelphiJSON<TTestRec>.Deserialize(res);

  Assert.AreEqual('abc', tmp.data);
  Assert.AreEqual(42, tmp.number);
  Assert.AreEqual(true, tmp.statement);
  Assert.AreEqual(EncodeDateTime(2012, 05, 23, 18, 25, 43, 123), tmp.dt);

end;

procedure TRecordTests.SerializationTest;
const
  res = '{"text":"abc", "int":42, "bool":true, "dt":"2012-04-23T18:25:43.511Z"}';
var
  tmp: TTestRec;
  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := 'abc';
  tmp.number := 42;
  tmp.statement := true;
  tmp.dt := EncodeDateTime(2012, 04, 23, 18, 25, 43, 511);

  ser := DelphiJSON<TTestRec>.SerializeJ(tmp);

  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;

end;

procedure TRecordTests.SerializeManagedRecord;
const
  res = '{"text":"abc", "int":42, "bool":true, "dt":"2012-04-23T18:25:43.511Z"}';
var
  tmp: TManagedRecord;
  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := 'abc';
  tmp.number := 42;
  tmp.statement := true;
  tmp.dt := EncodeDateTime(2012, 04, 23, 18, 25, 43, 511);

  ser := DelphiJSON<TManagedRecord>.SerializeJ(tmp);

  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;

end;

{TManagedRecord}

class operator TManagedRecord.Initialize(out dest: TManagedRecord);
begin
  dest.numberThatShouldGetInitialized := 45684211;
end;

initialization

TDUnitX.RegisterTestFixture(TRecordTests);

end.
