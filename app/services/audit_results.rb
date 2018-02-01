# AuditResults allows the correct granularity of information to be reported in various contexts.
#   By collecting all the result information in this class, we keep the audit check code cleaner, and
#   enable an easy way to provide:
#    - the correct HTTP response code for ReST calls routed via controller
#    - error information reported to workflows
#    - information to Rails log
#    - in the future, this may also include reporting to the provenance database as well
#
# All results are kept in the result_array attribute, which is returned by the report_results method.
#   result_array = [result1, result2]
#   result1 = {response_code => msg}
#   result2 = {response_code => msg}
class AuditResults

  INVALID_ARGUMENTS = :invalid_arguments
  VERSION_MATCHES = :version_matches
  ARG_VERSION_GREATER_THAN_DB_OBJECT = :arg_version_greater_than_db
  ARG_VERSION_LESS_THAN_DB_OBJECT = :arg_version_less_than_db
  CREATED_NEW_OBJECT = :created_new_object
  DB_UPDATE_FAILED = :db_update_failed
  OBJECT_ALREADY_EXISTS = :object_already_exists
  OBJECT_DOES_NOT_EXIST = :object_does_not_exist
  PC_STATUS_CHANGED = :pc_status_changed
  UNEXPECTED_VERSION = :unexpected_version
  INVALID_MOAB = :invalid_moab
  PC_PO_VERSION_MISMATCH = :pc_po_version_mismatch
  ONLINE_MOAB_DOES_NOT_EXIST = :online_moab_does_not_exist

  RESPONSE_CODE_TO_MESSAGES = {
    INVALID_ARGUMENTS => "encountered validation error(s): %{addl}",
    VERSION_MATCHES => "actual version (%{actual_version}) matches %{addl} db version",
    ARG_VERSION_GREATER_THAN_DB_OBJECT => "actual version (%{actual_version}) greater than %{addl} db version",
    ARG_VERSION_LESS_THAN_DB_OBJECT => "actual version (%{actual_version}) less than %{addl} db version; ERROR!",
    CREATED_NEW_OBJECT => "added object to db as it did not exist",
    DB_UPDATE_FAILED => "db update failed: %{addl}",
    OBJECT_ALREADY_EXISTS => "%{addl} db object already exists",
    OBJECT_DOES_NOT_EXIST => "%{addl} db object does not exist",
    PC_STATUS_CHANGED => "PreservedCopy status changed from %{old_status} to %{new_status}",
    UNEXPECTED_VERSION => "actual version (%{actual_version}) has unexpected relationship to %{addl} db version; ERROR!",
    INVALID_MOAB => "Invalid moab, validation errors: %{addl}",
    PC_PO_VERSION_MISMATCH => "PreservedCopy online moab version %{pc_version} does not match PreservedObject current_version %{po_version}",
    ONLINE_MOAB_DOES_NOT_EXIST => "db has moab that is not found online"
  }.freeze

  WORKFLOW_REPORT_CODES = [
    ARG_VERSION_LESS_THAN_DB_OBJECT,
    DB_UPDATE_FAILED,
    OBJECT_ALREADY_EXISTS,
    OBJECT_DOES_NOT_EXIST,
    UNEXPECTED_VERSION,
    PC_PO_VERSION_MISMATCH,
    ONLINE_MOAB_DOES_NOT_EXIST
  ].freeze

  DB_UPDATED_CODES = [
    CREATED_NEW_OBJECT,
    PC_STATUS_CHANGED
  ].freeze

  def self.logger_severity_level(result_code)
    case result_code
    when INVALID_ARGUMENTS then Logger::ERROR
    when VERSION_MATCHES then Logger::INFO
    when ARG_VERSION_GREATER_THAN_DB_OBJECT then Logger::INFO
    when ARG_VERSION_LESS_THAN_DB_OBJECT then Logger::ERROR
    when CREATED_NEW_OBJECT then Logger::INFO
    when DB_UPDATE_FAILED then Logger::ERROR
    when OBJECT_ALREADY_EXISTS then Logger::ERROR
    when OBJECT_DOES_NOT_EXIST then Logger::ERROR
    when PC_STATUS_CHANGED then Logger::INFO
    when UNEXPECTED_VERSION then Logger::ERROR
    when INVALID_MOAB then Logger::ERROR
    when PC_PO_VERSION_MISMATCH then Logger::ERROR
    when ONLINE_MOAB_DOES_NOT_EXIST then Logger::ERROR
    end
  end

  attr_reader :result_array, :msg_prefix, :druid
  attr_accessor :actual_version

  def initialize(druid, actual_version, endpoint)
    @druid = druid
    @actual_version = actual_version
    @msg_prefix = "PreservedObjectHandler(#{druid}, #{actual_version}, #{endpoint.endpoint_name if endpoint})"
    @result_array = []
  end

  def add_result(code, msg_args=nil)
    result_array << result_hash(code, msg_args)
  end

  # used when updates wrapped in transaction fail, and there is a need to ensure there is no db updated result
  def remove_db_updated_results
    result_array.delete_if { |res_hash| DB_UPDATED_CODES.include?(res_hash.keys.first) }
  end

  # output results to Rails.logger and send errors to WorkflowErrorsReporter
  # @return Array<Hash>
  #   results = [result1, result2]
  #   result1 = {response_code => msg}
  #   result2 = {response_code => msg}
  def report_results
    candidate_workflow_results = []
    result_array.each do |r|
      log_result(r)
      if r.key?(INVALID_MOAB)
        WorkflowErrorsReporter.update_workflow(druid, 'moab-valid', r.values.first)
      elsif WORKFLOW_REPORT_CODES.include?(r.keys.first)
        candidate_workflow_results << r
      end
    end
    stack_trace = caller(0..1).join("\n")
    report_errors_to_workflows(candidate_workflow_results, stack_trace)
    result_array
  end

  private

  def result_hash(code, msg_args=nil)
    { code => result_code_msg(code, msg_args) }
  end

  def report_errors_to_workflows(candidate_workflow_results, stack_trace)
    return if candidate_workflow_results.empty?
    value_array = []
    candidate_workflow_results.each do |result_hash|
      result_hash.each_value do |val|
        value_array << val
      end
    end
    value_array << stack_trace
    WorkflowErrorsReporter.update_workflow(druid, 'preservation-audit', value_array.join(" || "))
  end

  def log_result(result)
    severity = self.class.logger_severity_level(result.keys.first)
    msg = result.values.first
    Rails.logger.log(severity, msg)
  end

  def result_code_msg(code, addl=nil)
    arg_hash = { actual_version: actual_version }
    if addl.is_a?(Hash)
      arg_hash.merge!(addl)
    else
      arg_hash[:addl] = addl
    end

    "#{msg_prefix} #{RESPONSE_CODE_TO_MESSAGES[code] % arg_hash}"
  end
end