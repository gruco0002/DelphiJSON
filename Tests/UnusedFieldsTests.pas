unit UnusedFieldsTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  [DJSerializable]
  TTest = class
  public
    [DJValue('data')]
    data: string;
  end;

  [DJSerializable]
  [DJNoUnusedJSONFields]
  TTest2 = class
  public
    [DJValue('data')]
    data: string;
  end;

  [DJSerializable]
  [DJNoUnusedJSONFields(false)]
  TTest3 = class
  public
    [DJValue('data')]
    data: string;
  end;

  [TestFixture]
  TUnusedFieldsTests = class(TObject)
  public

    [Test]
    procedure TestSettingsDefault;

    [Test]
    procedure TestSettingsAltered;

    [Test]
    procedure TestAttribute;

    [Test]
    procedure TestAttributeFalse;

  end;

implementation

uses
  DelphiJSONTypes;

{TUnusedFieldsTests}

procedure TUnusedFieldsTests.TestAttribute;
const
  res = '{"data": "test"}';
  res2 = '{"data": "test", "abc": true}';
var
  setting: TDJSettings;
  deserialized: TTest2;
begin
  setting := TDJSettings.Default;
  setting.AllowUnusedJSONFields := false;

  deserialized := nil;
  deserialized := DelphiJSON<TTest2>.Deserialize(res);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;
  Assert.IsNull(deserialized);

  deserialized := DelphiJSON<TTest2>.Deserialize(res, setting);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;
  Assert.IsNull(deserialized);

  Assert.WillRaise(
    procedure
    begin
      deserialized := DelphiJSON<TTest2>.Deserialize(res2);
    end, EDJUnusedFieldsError);

  Assert.WillRaise(
    procedure
    begin
      deserialized := DelphiJSON<TTest2>.Deserialize(res2, setting);
    end, EDJUnusedFieldsError);
  setting.Free;
end;

procedure TUnusedFieldsTests.TestAttributeFalse;
const
  res = '{"data": "test"}';
  res2 = '{"data": "test", "abc": true}';
var
  setting: TDJSettings;
  deserialized: TTest3;
begin
  setting := TDJSettings.Default;
  setting.AllowUnusedJSONFields := false;

  deserialized := nil;
  deserialized := DelphiJSON<TTest3>.Deserialize(res);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;
  Assert.IsNull(deserialized);

  deserialized := DelphiJSON<TTest3>.Deserialize(res, setting);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;
  Assert.IsNull(deserialized);

  Assert.WillNotRaise(
    procedure
    begin
      deserialized := DelphiJSON<TTest3>.Deserialize(res2);

    end, EDJError);
  deserialized.Free;
  deserialized := nil;
  Assert.WillNotRaise(
    procedure
    begin
      deserialized := DelphiJSON<TTest3>.Deserialize(res2, setting);
    end, EDJError);
  deserialized.Free;

  setting.Free;

end;

procedure TUnusedFieldsTests.TestSettingsAltered;
const
  res = '{"data": "test"}';
  res2 = '{"data": "test", "abc": true}';
var
  setting: TDJSettings;
  deserialized: TTest;
begin
  setting := TDJSettings.Default;
  setting.AllowUnusedJSONFields := false;

  deserialized := nil;
  deserialized := DelphiJSON<TTest>.Deserialize(res);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;

  Assert.IsNull(deserialized);

  Assert.WillRaise(
    procedure
    begin
      deserialized := DelphiJSON<TTest>.Deserialize(res2, setting);
    end, EDJUnusedFieldsError);
  setting.Free;
end;

procedure TUnusedFieldsTests.TestSettingsDefault;
const
  res = '{"data": "test"}';
  res2 = '{"data": "test", "abc": true}';
var
  setting: TDJSettings;
  deserialized: TTest;
begin

  setting := TDJSettings.Default;

  deserialized := nil;
  deserialized := DelphiJSON<TTest>.Deserialize(res2);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  deserialized := nil;

  Assert.IsNull(deserialized);

  deserialized := DelphiJSON<TTest>.Deserialize(res2, setting);
  Assert.IsNotNull(deserialized);
  Assert.AreEqual('test', deserialized.data);
  deserialized.Free;
  setting.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TUnusedFieldsTests);

end.
