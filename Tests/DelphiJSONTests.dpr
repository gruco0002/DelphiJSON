program DelphiJSONTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}

uses
  FastMM4,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  BasicTests in 'BasicTests.pas',
  JSONComparer in 'JSONComparer.pas',
  JSONComparerTests in 'JSONComparerTests.pas',
  EnumerableTests in 'EnumerableTests.pas',
  RecordTests in 'RecordTests.pas',
  DateAndTimeTests in 'DateAndTimeTests.pas',
  DefaultValueTests in 'DefaultValueTests.pas',
  ConverterTests in 'ConverterTests.pas',
  ConstructorTests in 'ConstructorTests.pas',
  NonNilableTests in 'NonNilableTests.pas',
  RequiredTests in 'RequiredTests.pas',
  SerializableAttrTests in 'SerializableAttrTests.pas',
  ListTests in 'ListTests.pas',
  DictionaryTests in 'DictionaryTests.pas',
  ArrayTests in 'ArrayTests.pas',
  CycleTests in 'CycleTests.pas',
  AutoFreeTest in 'AutoFreeTest.pas',
  ErrorTests in 'ErrorTests.pas',
  UnusedFieldsTests in 'UnusedFieldsTests.pas',
  JSONValueTests in 'JSONValueTests.pas',
  RecordArrayTests in 'RecordArrayTests.pas',
  ToAndFromJsonAttributesTests in 'ToAndFromJsonAttributesTests.pas',
  NullIfEmptyStringTests in 'NullIfEmptyStringTests.pas',
  CustomSettingsTests in 'CustomSettingsTests.pas';

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    // Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    // Create the test runner
    runner := TDUnitX.CreateRunner;
    // Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    // tell the runner how we will log things
    // Log to the console window
    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);
    // Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create
      (TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False;
    // When true, Assertions must be made during tests;

    // Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

{$IFNDEF CI}
    // We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
{$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;

end.
