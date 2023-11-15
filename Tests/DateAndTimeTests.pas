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

    [Test]
    procedure TestFormatError;

    [Test]
    procedure TestTTimeSer;

    [Test]
    procedure TestTTimeDer;

    [Test]
    procedure TestTDateSer;

    [Test]
    procedure TestTDateDer;

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

procedure TDateAndTimeTests.TestFormatError;
const
  res = '"2020-09-12T10:40:42.153+02:00"';
  resInvalid = '"2020-09-12T-10:40:42.153+02:00"';
var
  dt: TDateTime;
begin

  Assert.WillRaise(
    procedure
    begin
      dt := DelphiJSON<TDateTime>.Deserialize(resInvalid);
    end, EDJFormatError);

  Assert.WillRaise(
    procedure
    begin
      dt := DelphiJSON<TDateTime>.Deserialize('"hello World"');
    end, EDJFormatError);

  Assert.WillRaise(
    procedure
    begin
      dt := DelphiJSON<TDateTime>.Deserialize('""');
    end, EDJFormatError);

  Assert.WillNotRaise(
    procedure
    begin
      dt := DelphiJSON<TDateTime>.Deserialize(res);
    end, EDJFormatError);
end;

procedure TDateAndTimeTests.TestTDateDer;
const
  res = '"2020-10-05"';
var
  dt: TDate;
  de: TDate;
begin
  dt := EncodeDate(2020, 10, 5);
  de := DelphiJSON<TDate>.Deserialize(res);
  Assert.AreEqual(dt, de);
end;

procedure TDateAndTimeTests.TestTDateSer;
const
  res = '1983-06-12';
var
  ser: TJSONValue;
  desired: TJSONString;
  data: TDate;
begin
  data := EncodeDate(1983, 6, 12);
  desired := TJSONString.Create(res);
  ser := DelphiJSON<TDate>.SerializeJ(data);

  Assert.IsTrue(JSONEquals(desired, ser));

  desired.Free;
  ser.Free;
end;

procedure TDateAndTimeTests.TestTTimeDer;
const
  res = '"13:56:12.24"';
var
  dt: TTime;
  de: TTime;
begin
  dt := EncodeTime(13, 56, 12, 24);
  de := DelphiJSON<TTime>.Deserialize(res);
  Assert.AreEqual(dt, de);
end;

procedure TDateAndTimeTests.TestTTimeSer;
const
  res = '04:03:42.568';
var
  ser: TJSONValue;
  desired: TJSONString;
  data: TTime;
begin
  data := EncodeTime(4, 3, 42, 568);
  desired := TJSONString.Create(res);
  ser := DelphiJSON<TTime>.SerializeJ(data);

  Assert.IsTrue(JSONEquals(desired, ser));

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
