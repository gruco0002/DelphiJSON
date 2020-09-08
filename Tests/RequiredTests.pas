unit RequiredTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  [DJSerializableAttribute]
  TTestSettings = class
  public

    [DJValue('str')]
    [DJRequiredAttribute(false)]
    str: String;

    [DJValue('i')]
    i: Integer;

    [DJValue('f')]
    [DJRequiredAttribute(true)]
    f: Single;

  end;

  [DJSerializableAttribute]
  TTestAttr = class
  public

    [DJValue('str')]
    [DJRequiredAttribute(false)]
    str: String;

    [DJValue('f')]
    [DJRequiredAttribute(true)]
    f: Single;

  end;

  [TestFixture]
  TRequiredTests = class(TObject)
  public

    [Test]
    procedure TestRequiredAttrDes;
    [Test]
    procedure TestRequiredAttrDesException;

    [Test]
    procedure TestRequiredSettingsDer;
    [Test]
    procedure TestRequiredSettingsDerException;

  end;

implementation

uses
  JSONComparer, System.JSON;

{ TRequiredTests }

procedure TRequiredTests.TestRequiredAttrDes;
const
  res = '{ "f": 9.23 }';
var
  tmp: TTestAttr;
begin
  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TTestAttr>.Deserialize(res);

      Assert.AreEqual('', tmp.str);
      Assert.AreEqual(Single(9.23), tmp.f);

      tmp.Free;
    end, EDJRequiredError);
end;

procedure TRequiredTests.TestRequiredAttrDesException;
const
  res = '{ "str": "abc" }';
var
  tmp: TTestAttr;
begin
  Assert.WillRaise(
    procedure
    begin
      DelphiJSON<TTestAttr>.Deserialize(res);
    end, EDJRequiredError);
end;

procedure TRequiredTests.TestRequiredSettingsDer;
const
  res = '{ "f": 42.42 }';
var
  tmp: TTestSettings;
  settings: TDJSettings;
begin
  settings := TDJSettings.Default;
  settings.RequiredByDefault := false;

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TTestSettings>.Deserialize(res, settings);
    end, EDJRequiredError);
  Assert.AreEqual('', tmp.str);
  Assert.AreEqual(Single(42.42), tmp.f);
  Assert.AreEqual(0, tmp.i);

  tmp.Free;
  settings.Free;
end;

procedure TRequiredTests.TestRequiredSettingsDerException;
const
  res = '{ "str": "abc", "i": 12 }';
var
  tmp: TTestSettings;
  settings: TDJSettings;
begin
  settings := TDJSettings.Default;
  settings.RequiredByDefault := false;

  Assert.WillRaise(
    procedure
    begin
      DelphiJSON<TTestSettings>.Deserialize(res, settings);
    end, EDJRequiredError);

  settings.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TRequiredTests);

end.
