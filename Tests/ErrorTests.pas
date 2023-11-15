unit ErrorTests;

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

    [DJValue('object')]
    test: TTest;
  end;

  [TestFixture]
  TErrorTests = class(TObject)
  public

    [test]
    procedure TestPath1;

    [test]
    procedure TestPath2;

  end;

implementation

uses
  DelphiJSONTypes;

{TErrorTests}

procedure TErrorTests.TestPath1;
const
  res = '{ "list": null }';
var
  raised: Boolean;
begin
  raised := false;
  try
    DelphiJSON<TTest>.Deserialize(res);
  except
    on E: EDJNilError do
    begin
      raised := true;
      Assert.AreEqual('list', E.FullPath);
    end;
  end;
  Assert.IsTrue(raised);

end;

procedure TErrorTests.TestPath2;
const
  res = '{ "list": [], "object": { "list": null } }';
var
  raised: Boolean;
begin
  raised := false;
  try
    DelphiJSON<TTest>.Deserialize(res);
  except
    on E: EDJNilError do
    begin
      raised := true;
      Assert.AreEqual('object>list', E.FullPath);
    end;
  end;
  Assert.IsTrue(raised);
end;

initialization

TDUnitX.RegisterTestFixture(TErrorTests);

end.
