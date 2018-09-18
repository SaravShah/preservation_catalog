# Confirms that a CompleteMoab is fully/properly replicated to all target zip endpoints.
# Usage info:
# MoabReplicationAuditJob.perform_later(cm)
class MoabReplicationAuditJob < ApplicationJob
  queue_as :moab_replication_audit
  delegate :check_child_zip_part_attributes, to: Audit::CatalogToArchive
  delegate :check_aws_replicated_zipped_moab_version, to: PreservationCatalog::S3::Audit
  delegate :logger, to: Audit::CatalogToArchive

  # @param [CompleteMoab] verify that the zip exists on the endpoint
  def perform(complete_moab)
    druid = complete_moab.preserved_object.druid

    results = AuditResults.new(druid, nil, complete_moab.moab_storage_root, "MoabReplicationAuditJob")

    backfill_missing_zmvs(complete_moab, results) if Settings.replication.audit_should_backfill

    complete_moab.zipped_moab_versions.each do |zmv|
      # Leave the part of MoabReplicationAuditJob that checks parts count consistency etc as-is.
      next unless check_child_zip_part_attributes(zmv, results)
      # Remove direct invocation of the method that checks the state of the ZippedMoabVersions (and their ZipParts) on the cloud.
      # Instead, introduce a new worker class for each S3 endpoint
      # for example, ZippedMoabVersionAuditWestJob, ZippedMoabVersionAuditEastJob
      # figure out which endpoint name and send to the appropriate worker
      # endpoint_name = zmv.zip_endpoint.endpoint_name
      # case endpoint_name
      # when 'aws_s3_west_2'
      #   ZippedMoabVersionAuditWestJob.perform_later(zmv)
      # when 'aws_s3_east_1'
      #   ZippedMoabVersionAuditEastJob.perform_later(zmv)
      # end
      check_aws_replicated_zipped_moab_version(zmv, results)
    end

    results.report_results(logger)
  end

  private

  def backfill_missing_zmvs(complete_moab, results)
    backfilled_zmvs = complete_moab.create_zipped_moab_versions!
    return if backfilled_zmvs.empty?

    results.add_result(
      AuditResults::ZMV_BACKFILL,
      version_endpoint_pairs: format_backfilled_zmvs(backfilled_zmvs)
    )
  end

  def format_backfilled_zmvs(backfilled_zmvs)
    backfilled_zmvs.map { |bz| "#{bz.version} to #{bz.zip_endpoint.endpoint_name}" }.sort.join("; ")
  end
end
