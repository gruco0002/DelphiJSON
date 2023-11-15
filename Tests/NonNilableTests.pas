unit NonNilableTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON, System.Generics.Collections;

type

  [DJSerializable]
  TTest = class
  public

    [DJValue('list')]
    [DJNonNilable]
    list: TList<String>;
  end;

  [TestFixture]
  TNonNilableTests = class(TObject)
  public

    [Test]
    procedure TestSerialization;

    [Test]
    procedure TestDeserialization;

    [Test]
    procedure TestSettingsSerialization;

    [Test]
    procedure TestSettingsDeserialization;

  end;

implementation

uses
  System.JSON, JsonComparer;

{TNonNilableTests}

procedure TNonNilableTests.TestDeserialization;
const
  res = '{ "list": null }';
begin
  Assert.WillRaise(
    procedure
    begin
      DelphiJSON<TTest>.Deserialize(res);
    end, EDJNilError);
end;

procedure TNonNilableTests.TestSerialization;
var
  tmp: TTest;
begin
  tmp := TTest.Create;
  tmp.list := nil;

  Assert.WillRaise(
    procedure
    begin
      DelphiJSON<TTest>.Serialize(tmp);
    end, EDJNilError);

  tmp.Free;
end;

procedure TNonNilableTests.TestSettingsDeserialization;
const
  res = '{ "list": null }';
var
  settings: TDJSettings;
  tmp: TTest;
begin
  settings := TDJSettings.Default;
  settings.IgnoreNonNillable := true;

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TTest>.Deserialize(res, settings);
    end, EDJNilError);
  Assert.IsNull(tmp.list);
  tmp.Free;
  settings.Free;
end;

procedure TNonNilableTests.TestSettingsSerialization;
const
  res = '{ "list": null }';
var
  settings: TDJSettings;
  tmp: TTest;

  jValue: TJSONValue;
  desired: TJSONValue;
begin
  settings := TDJSettings.Default;
  settings.IgnoreNonNillable := true;

  tmp := TTest.Create;
  tmp.list := nil;

  Assert.WillNotRaise(
    procedure
    begin
      jValue := DelphiJSON<TTest>.SerializeJ(tmp, settings);
    end, EDJNilError);
  desired := TJSONObject.ParseJSONValue(res);
  Assert.IsTrue(JsonComparer.JSONEquals(jValue, desired));

  jValue.Free;
  desired.Free;
  tmp.Free;
  settings.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TNonNilableTests);

end.
