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

    [Test]
    procedure TestUTCSettingsSerialization;

    [Test]
    procedure TestUTCSettingsDeserialization;

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

procedure TDateAndTimeTests.TestUTCSettingsDeserialization;
const
  res = '"2020-08-23T10:40:42.153-05:00"';
var
  dt: TDateTime;
  settings: TDJSettings;
  timezone: TTimeZone;
begin
  timezone := TTimeZone.Local;

  settings := TDJSettings.Default;

  dt := DelphiJSON<TDateTime>.Deserialize(res);
  Assert.AreEqual(EncodeDateTime(2020, 8, 23, 15, 40, 42, 153), dt);

  settings.DateTimeReturnUTC := true;

  dt := DelphiJSON<TDateTime>.Deserialize(res, settings);
  Assert.AreEqual(EncodeDateTime(2020, 8, 23, 15, 40, 42, 153), dt);

  settings.DateTimeReturnUTC := false;

  dt := DelphiJSON<TDateTime>.Deserialize(res, settings);
  Assert.AreEqual(timezone.ToLocalTime(EncodeDateTime(2020, 8, 23, 15, 40, 42,
    153)), dt);

  settings.Free;

end;

procedure TDateAndTimeTests.TestUTCSettingsSerialization;
var
  dt: TDateTime;
  ser: TJSONValue;
  desired: TJSONValue;
  settings: TDJSettings;
begin
  dt := EncodeDateTime(2020, 4, 23, 10, 12, 11, 154);

  settings := TDJSettings.Default;
  settings.DateTimeReturnUTC := false;

  ser := DelphiJSON<TDateTime>.SerializeJ(dt, settings);
  desired := TJSONString.Create(DateToISO8601(dt, false));
  Assert.IsTrue(JSONEquals(ser, desired));

  desired.Free;
  ser.Free;
  desired := nil;
  ser := nil;

  settings.DateTimeReturnUTC := true;
  ser := DelphiJSON<TDateTime>.SerializeJ(dt, settings);
  desired := TJSONString.Create(DateToISO8601(dt, true));
  Assert.IsTrue(JSONEquals(ser, desired));

  desired.Free;
  ser.Free;

  settings.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TDateAndTimeTests);

end.
