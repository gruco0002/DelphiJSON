unit ToAndFromJsonAttributesTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TToAndFromJsonAttributesTests = class(TObject)
  public

    [Test]
    procedure TestSerializationAtRoot;

    [Test]
    procedure TestSerializationAtMember;

    [Test]
    procedure TestDeserializationAtRoot;

    [Test]
    procedure TestDeserializationAtMember;

  end;

implementation

uses
  DelphiJSON, System.SysUtils, System.JSON, JSONComparer;

type

  [DJSerializable]
  TTestRecord = record
  public
    data1: string;
    data2: Integer;

    [DJFromJSONFunction]
    class function FromJSON(stream: TDJJsonStream; settings: TDJSettings): TTestRecord; static;

    [DJToJSONFunction]
    procedure ToJSON(stream: TDJJsonStream; settings: TDJSettings);

  end;

  [DJSerializable]
  TContainingRecord = record
  public

    [DJValue('mySpecialRecord')]
    mySpecialRecord: TTestRecord;
  end;

  {TTestRecord}

class function TTestRecord.FromJSON(stream: TDJJsonStream; settings: TDJSettings): TTestRecord;
var
  str: string;
begin
  if stream.ReadGetType <> djstString then
  begin
    raise EDJError.Create('Invalid type!', []);
  end;

  str := stream.ReadValueString;

  Result.data1 := str;
  Result.data2 := 555333111;
end;

procedure TTestRecord.ToJSON(stream: TDJJsonStream; settings: TDJSettings);
begin
  stream.WriteValueString(self.data1 + ' -- ' + self.data2.ToString)
end;

{TToAndFromJsonAttributesTests}

procedure TToAndFromJsonAttributesTests.TestSerializationAtMember;
const
  res = '{"mySpecialRecord":"Hello World -- 42"}';
var
  tmp: TContainingRecord;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.mySpecialRecord.data1 := 'Hello World';
  tmp.mySpecialRecord.data2 := 42;

  ser := DelphiJSON<TContainingRecord>.SerializeJ(tmp);

  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

procedure TToAndFromJsonAttributesTests.TestDeserializationAtMember;
const
  res = '{"mySpecialRecord":"An apple a day -- 321"}';
var
  tmp: TContainingRecord;
begin
  tmp := DelphiJSON<TContainingRecord>.Deserialize(res);
  Assert.AreEqual('An apple a day -- 321', tmp.mySpecialRecord.data1);
  Assert.AreEqual(555333111, tmp.mySpecialRecord.data2);
end;

procedure TToAndFromJsonAttributesTests.TestSerializationAtRoot;
const
  res = '"Nice weather -- 123"';
var
  tmp: TTestRecord;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data1 := 'Nice weather';
  tmp.data2 := 123;

  ser := DelphiJSON<TTestRecord>.SerializeJ(tmp);

  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

procedure TToAndFromJsonAttributesTests.TestDeserializationAtRoot;
const
  res = '"Sun is shining -- 111"';
var
  tmp: TTestRecord;
begin
  tmp := DelphiJSON<TTestRecord>.Deserialize(res);
  Assert.AreEqual('Sun is shining -- 111', tmp.data1);
  Assert.AreEqual(555333111, tmp.data2);
end;

initialization

TDUnitX.RegisterTestFixture(TToAndFromJsonAttributesTests);

end.
