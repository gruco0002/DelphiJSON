unit DateAndTimeTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TDateAndTimeTests = class(TObject)
  public

    [Test]
    procedure DateTimeSerialization;

    [Test]
    procedure DateTimeDeserialization;

  end;

implementation

uses
  DelphiJSON, System.SysUtils, System.DateUtils, JSONComparer, System.JSON;

{ TDateAndTimeTests }

procedure TDateAndTimeTests.DateTimeDeserialization;
const
  res = '"2020-08-23T10:40:42.153Z"';
var
  dt: TDateTime;
begin
  dt := DelphiJSON<TDateTime>.Deserialize(res);
  Assert.AreEqual(EncodeDateTime(2020, 8, 23, 10, 40, 42, 153), dt);
end;

procedure TDateAndTimeTests.DateTimeSerialization;
const
  res = '"2020-04-23T10:12:11.154Z"';
var
  dt: TDateTime;
  ser: TJSONValue;
  desired: TJSONValue;
begin
  dt := EncodeDateTime(2020, 4, 23, 10, 12, 11, 154);

  ser := DelphiJSON<TDateTime>.SerializeJ(dt);

  desired := TJSONObject.ParseJSONValue(res);

  Assert.IsTrue(JSONEquals(ser, desired));

  desired.Free;
  ser.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TDateAndTimeTests);

end.
