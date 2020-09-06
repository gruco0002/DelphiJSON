unit ConverterTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON, System.JSON;

type
  TUpperConv = class(DJConverterAttribute<String>)
  public
    function ToJSON(value: String): TJSONValue; override;
    function FromJSON(value: TJSONValue): String; override;
  end;

  [DJSerializableAttribute]
  TTest = class
  public
    [DJValue('message')]
    [TUpperConv]
    msg: string;

  end;

  [TestFixture]
  TConverterTests = class(TObject)
  public

    [Test]
    procedure TestUppercaseConverter1;

    [Test]
    procedure TestUppercaseConverter2;

  end;

implementation

uses
  System.SysUtils, System.StrUtils, JSONComparer;

{ TUpperConv }

function TUpperConv.FromJSON(value: TJSONValue): String;
begin
  if not(value is TJSONString) then
  begin
    raise EDJError.Create('wrong type', '');
  end;
  Result := (value as TJSONString).value.toUpper;
end;

function TUpperConv.ToJSON(value: String): TJSONValue;
begin
  Result := TJSONString.Create(value.toUpper);
end;

{ TConverterTests }

procedure TConverterTests.TestUppercaseConverter1;
const
  res = '{"message": "Hello World" }';
var
  tmp: TTest;
begin

  tmp := DelphiJSON<TTest>.Deserialize(res);

  Assert.AreEqual('HELLO WORLD', tmp.msg);

  tmp.Free;

end;

procedure TConverterTests.TestUppercaseConverter2;
const
  res = '{"message": "WOW!"}';
var
  tmp: TTest;
  jValue: TJSONValue;
  resValue: TJSONValue;
begin
  tmp := TTest.Create;
  tmp.msg := 'wow!';

  jValue := DelphiJSON<TTest>.SerializeJ(tmp);
  tmp.Free;

  resValue := TJSONObject.ParseJSONValue(res);

  Assert.IsTrue(JSONComparer.JSONEquals(resValue, jValue));
  resValue.Free;
  jValue.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TConverterTests);

end.
