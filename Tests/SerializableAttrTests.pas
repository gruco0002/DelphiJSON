unit SerializableAttrTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  TNoAttr = class
  public
    [DJValue('value')]
    value: String;
  end;

  [DJSerializableAttribute]
  TAttr = class
  public
    [DJValue('value')]
    value: String;
  end;

  [TestFixture]
  TSerializableAttrTests = class(TObject)
  public

    [Test]
    procedure TestDeserialize;

    [Test]
    procedure TestSerialize;

  end;

implementation

uses
  System.JSON, JSONComparer, DelphiJSONTypes;

{TSerializableAttrTests}

procedure TSerializableAttrTests.TestDeserialize;
const
  res = '{"value":"Hello World"}';
var
  noAtt: TNoAttr;
  att: TAttr;
  settings: TDJSettings;
begin

  Assert.WillRaise(
    procedure
    begin
      noAtt := DelphiJSON<TNoAttr>.Deserialize(res);
    end, EDJError);
  Assert.WillNotRaise(
    procedure
    begin
      att := DelphiJSON<TAttr>.Deserialize(res);

    end, EDJError);
  att.Free;
  att := nil;

  settings := TDJSettings.Default;
  settings.RequireSerializableAttributeForNonRTLClasses := true;
  Assert.WillRaise(
    procedure
    begin
      noAtt := DelphiJSON<TNoAttr>.Deserialize(res, settings);
    end, EDJError);
  Assert.WillNotRaise(
    procedure
    begin
      att := DelphiJSON<TAttr>.Deserialize(res, settings);
    end, EDJError);
  att.Free;
  att := nil;
  settings.RequireSerializableAttributeForNonRTLClasses := false;
  Assert.WillNotRaise(
    procedure
    begin
      noAtt := DelphiJSON<TNoAttr>.Deserialize(res, settings);

    end, EDJError);
  noAtt.Free;
  noAtt := nil;
  Assert.WillNotRaise(
    procedure
    begin
      att := DelphiJSON<TAttr>.Deserialize(res, settings);
    end, EDJError);
  att.Free;
  settings.Free;
end;

procedure TSerializableAttrTests.TestSerialize;
var
  noAtt: TNoAttr;
  att: TAttr;
  desired: TJSONObject;
  settings: TDJSettings;
  result: TJSONValue;
begin
  noAtt := TNoAttr.Create;
  noAtt.value := 'Hello World';
  att := TAttr.Create;
  att.value := 'Hello World';

  desired := TJSONObject.Create;
  desired.AddPair('value', TJSONString.Create('Hello World'));

  Assert.WillRaise(
    procedure
    begin
      result := DelphiJSON<TNoAttr>.SerializeJ(noAtt);
    end, EDJError);
  Assert.WillNotRaise(
    procedure
    begin
      result := DelphiJSON<TAttr>.SerializeJ(att);

    end, EDJError);
  Assert.IsTrue(JSONEquals(result, desired));
  result.Free;

  settings := TDJSettings.Default;
  settings.RequireSerializableAttributeForNonRTLClasses := true;
  Assert.WillRaise(
    procedure
    begin
      result := DelphiJSON<TNoAttr>.SerializeJ(noAtt, settings);
    end, EDJError);
  Assert.WillNotRaise(
    procedure
    begin
      result := DelphiJSON<TAttr>.SerializeJ(att, settings);

    end, EDJError);
  Assert.IsTrue(JSONEquals(result, desired));
  result.Free;

  settings.RequireSerializableAttributeForNonRTLClasses := false;
  Assert.WillNotRaise(
    procedure
    begin
      result := DelphiJSON<TNoAttr>.SerializeJ(noAtt, settings);

    end, EDJError);
  Assert.IsTrue(JSONEquals(result, desired));
  result.Free;
  Assert.WillNotRaise(
    procedure
    begin
      result := DelphiJSON<TAttr>.SerializeJ(att, settings);

    end, EDJError);
  Assert.IsTrue(JSONEquals(result, desired));
  result.Free;
  settings.Free;
  noAtt.Free;
  att.Free;
  desired.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TSerializableAttrTests);

end.
