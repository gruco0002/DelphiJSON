unit ConverterTests;

interface

uses
  DUnitX.TestFramework, DelphiJSONAttributes, DelphiJSONTypes;

type
  TUpperConv = class(DJConverterAttribute<String>)
  public
    procedure ToJSON(value: String; stream: TDJJsonStream); override;
    function FromJSON(stream: TDJJsonStream): String; override;
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
  System.SysUtils, System.StrUtils, JSONComparer, DelphiJSON, System.JSON;

{ TUpperConv }

function TUpperConv.FromJSON(stream: TDJJsonStream): String;
begin
  if stream.ReadGetType <> TDJJsonStream.TDJJsonStreamTypes.djstString then
  begin
    raise EDJError.Create('wrong type', nil);
  end;
  Result := stream.ReadValueString.toUpper;
end;

procedure TUpperConv.ToJSON(value: String; stream: TDJJsonStream);
begin
  stream.WriteValueString(value.toUpper);
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
