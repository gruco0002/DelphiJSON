unit NullIfEmptyStringTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TNullIfEmptyStringTests = class(TObject)
  public

    [Test]
    procedure TestWithAttribute;

    [Test]
    procedure TestWithoutAttribute;

    [Test]
    procedure TestNonEmptyWithAttribute;

    [Test]
    procedure TestNonEmptyWithoutAttribute;

  end;

implementation

uses
  DelphiJSON, DelphiJSONAttributes, DelphiJSONTypes, System.SysUtils, System.JSON, JSONComparer;

type

  [DJSerializable]
  TTestRecord = record
  public

    [DJValue('data')]
    data: string;

  end;

  [DJSerializable]
  TTestRecordWithAttr = record
  public

    [DJValue('data')]
    [DJNullIfEmptyString]
    data: string;

  end;

  {TNullIfEmptyStringTests}

procedure TNullIfEmptyStringTests.TestNonEmptyWithAttribute;
const
  res = '{"data":"Hello World"}';
var
  tmp: TTestRecordWithAttr;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := 'Hello World';

  ser := DelphiJSON<TTestRecordWithAttr>.SerializeJ(tmp);
  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

procedure TNullIfEmptyStringTests.TestNonEmptyWithoutAttribute;
const
  res = '{"data":"Hello from the codebase"}';
var
  tmp: TTestRecord;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := 'Hello from the codebase';

  ser := DelphiJSON<TTestRecord>.SerializeJ(tmp);
  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

procedure TNullIfEmptyStringTests.TestWithAttribute;
const
  res = '{"data":null}';
var
  tmp: TTestRecordWithAttr;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := '';

  ser := DelphiJSON<TTestRecordWithAttr>.SerializeJ(tmp);
  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

procedure TNullIfEmptyStringTests.TestWithoutAttribute;
const
  res = '{"data":""}';
var
  tmp: TTestRecord;

  ser: TJSONValue;
  desired: TJSONValue;
begin
  tmp.data := '';

  ser := DelphiJSON<TTestRecord>.SerializeJ(tmp);
  desired := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(ser, desired));

  ser.Free;
  desired.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TNullIfEmptyStringTests);

end.
