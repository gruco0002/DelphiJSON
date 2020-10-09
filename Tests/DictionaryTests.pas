unit DictionaryTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON, System.Generics.Collections;

type

  [TestFixture]
  TDictionaryTests = class(TObject)
  public

    [Test]
    procedure TestSerialization;

    [Test]
    procedure TestDeserialization;

    [Test]
    procedure TestSerStringKey;

    [Test]
    procedure TestDerStringKey;

    [Test]
    procedure TestSerStringKeyDisabled;

    [Test]
    procedure TestDerStringKeyDisabled;

  end;

implementation

uses
  System.JSON, JSONComparer;

{ TDictionaryTests }

procedure TDictionaryTests.TestDerStringKey;
const
  res = '{"Smith":56,"Neo":42,"Matrix":32}';
var
  dict: TDictionary<String, Integer>;
begin
  dict := DelphiJSON < TDictionary < String, Integer >>.Deserialize(res);

  Assert.AreEqual(3, dict.Count);
  Assert.IsTrue(dict.ContainsKey('Neo'));
  Assert.IsTrue(dict.ContainsKey('Smith'));
  Assert.IsTrue(dict.ContainsKey('Matrix'));

  Assert.AreEqual(56, dict['Smith']);
  Assert.AreEqual(42, dict['Neo']);
  Assert.AreEqual(32, dict['Matrix']);

  dict.Free;
end;

procedure TDictionaryTests.TestDerStringKeyDisabled;
const
  res1 = '{"Smith":56,"Neo":42,"Matrix":32}';
  res = '[{"key": "Smith", "value": 56},{"key": "Neo", "value": 42},{"key": "Matrix", "value": 32}]';
var
  dict: TDictionary<String, Integer>;
  setting: TDJSettings;
begin
  setting := TDJSettings.Default;
  setting.TreatStringDictionaryAsObject := false;
  Assert.WillRaise(
    procedure
    begin
      dict := DelphiJSON < TDictionary < String,
        Integer >>.Deserialize(res1, setting);
    end, EDJError);

  dict := DelphiJSON < TDictionary < String,
    Integer >>.Deserialize(res, setting);

  Assert.AreEqual(3, dict.Count);
  Assert.IsTrue(dict.ContainsKey('Neo'));
  Assert.IsTrue(dict.ContainsKey('Smith'));
  Assert.IsTrue(dict.ContainsKey('Matrix'));

  Assert.AreEqual(56, dict['Smith']);
  Assert.AreEqual(42, dict['Neo']);
  Assert.AreEqual(32, dict['Matrix']);

  dict.Free;
  setting.Free;

end;

procedure TDictionaryTests.TestDeserialization;
const
  res = '[{"key":56,"value":"Smith"},{"key":42,"value":"Neo"},{"key":32,"value":"Matrix"}]';
var
  dict: TDictionary<Integer, String>;
begin

  dict := DelphiJSON < TDictionary < Integer, String >>.Deserialize(res);

  Assert.AreEqual(3, dict.Count);
  Assert.IsTrue(dict.ContainsKey(56));
  Assert.IsTrue(dict.ContainsKey(42));
  Assert.IsTrue(dict.ContainsKey(32));

  Assert.AreEqual('Smith', dict[56]);
  Assert.AreEqual('Neo', dict[42]);
  Assert.AreEqual('Matrix', dict[32]);

  dict.Free;

end;

procedure TDictionaryTests.TestSerialization;
const
  res = '[{"key":56,"value":"Smith"},{"key":42,"value":"Neo"},{"key":32,"value":"Matrix"}]';
var
  dict: TDictionary<Integer, String>;
  desired: TJSONValue;
  serialized: TJSONValue;
begin
  dict := TDictionary<Integer, String>.Create;
  dict.Add(56, 'Smith');
  dict.Add(42, 'Neo');
  dict.Add(32, 'Matrix');

  desired := TJSONObject.ParseJSONValue(res);

  serialized := DelphiJSON < TDictionary < Integer, String >>.SerializeJ(dict);

  Assert.IsTrue(JSONEquals(desired, serialized, false));

  serialized.Free;
  desired.Free;
  dict.Free;
end;

procedure TDictionaryTests.TestSerStringKey;
const
  res = '{"Smith":56,"Neo":42,"Matrix":32}';
var
  dict: TDictionary<String, Integer>;
  desired: TJSONValue;
  serialized: TJSONValue;
begin
  dict := TDictionary<String, Integer>.Create;
  dict.Add('Smith', 56);
  dict.Add('Neo', 42);
  dict.Add('Matrix', 32);

  desired := TJSONObject.ParseJSONValue(res);

  serialized := DelphiJSON < TDictionary < String, Integer >>.SerializeJ(dict);

  Assert.IsTrue(JSONEquals(desired, serialized));

  serialized.Free;
  desired.Free;
  dict.Free;
end;

procedure TDictionaryTests.TestSerStringKeyDisabled;
const
  res = '[{"key": "Smith", "value": 56},{"key": "Neo", "value": 42},{"key": "Matrix", "value": 32}]';
var
  dict: TDictionary<String, Integer>;
  desired: TJSONValue;
  serialized: TJSONValue;
  setting: TDJSettings;
begin
  setting := TDJSettings.Default;
  setting.TreatStringDictionaryAsObject := false;
  dict := TDictionary<String, Integer>.Create;
  dict.Add('Smith', 56);
  dict.Add('Neo', 42);
  dict.Add('Matrix', 32);

  desired := TJSONObject.ParseJSONValue(res);

  serialized := DelphiJSON < TDictionary < String,
    Integer >>.SerializeJ(dict, setting);

  Assert.IsTrue(JSONEquals(desired, serialized, false));

  serialized.Free;
  desired.Free;
  dict.Free;
  setting.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TDictionaryTests);

end.
