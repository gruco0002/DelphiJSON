unit CustomSettingsTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TCustomSettingsTests = class(TObject)
  public

    [Test]
    procedure TestWithCustomSettings;

    [Test]
    procedure TestWithoutCustomSettings;

  end;

implementation

uses
  DelphiJSON, DelphiJSONTypes, System.SysUtils, System.JSON, JSONComparer;

type

  [DJSerializable]
  TTestRecord = record
  public
    data: string;

    [DJFromJSONFunction]
    class function FromJSON(stream: TDJJsonStream; settings: TDJSettings): TTestRecord; static;

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

  if settings.CustomProperties.ContainsKey('UppercaseIt') then
  begin
    Result.data := str.ToUpper;
  end
  else
  begin
    Result.data := str;
  end;
end;

{TCustomSettingsTests}

procedure TCustomSettingsTests.TestWithCustomSettings;
const
  res = '"abcDefg"';
var
  settings: TDJSettings;

  tmp: TTestRecord;
begin
  settings := TDJSettings.Default;
  settings.CustomProperties.Add('UppercaseIt', 'MAKE IT ALL IN UPPERCASE');

  tmp := DelphiJSON<TTestRecord>.Deserialize(res, settings);

  Assert.AreEqual('ABCDEFG', tmp.data);

  FreeAndNil(settings);
end;

procedure TCustomSettingsTests.TestWithoutCustomSettings;
const
  res = '"abcDefg"';
var
  tmp: TTestRecord;
begin
  tmp := DelphiJSON<TTestRecord>.Deserialize(res);

  Assert.AreEqual('abcDefg', tmp.data);
end;

initialization

TDUnitX.RegisterTestFixture(TCustomSettingsTests);

end.
