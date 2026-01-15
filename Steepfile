# Steepfile - Static type checking configuration for musa-dsl

target :lib do
  check "lib"
  signature "sig"

  library "json"
  library "logger"
  library "pathname"
  library "forwardable"
  library "singleton"

  configure_code_diagnostics do |hash|
    hash[Steep::Diagnostic::Ruby::UnknownConstant] = :hint
    hash[Steep::Diagnostic::Ruby::MethodDefinitionMissing] = :hint
    hash[Steep::Diagnostic::Ruby::NoMethod] = :hint
  end
end
