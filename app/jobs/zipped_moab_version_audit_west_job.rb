# This class is responsible for checking the ZipParts of a ZippedMoabVersion for a cloud endpoint
class ZippedMoabVersionAuditWestJob < ApplicationJob
  queue_as :zmv_replication_audit_west
  delegate :bucket, to: ::PreservationCatalog::S3

  def perform(west_zmv)
    west_zmv.zip_parts.where.not(status: :unreplicated).each do |part|
      aws_s3_object = bucket.object(part.s3_key)
      next unless check_existence(aws_s3_object, part)
      next unless compare_checksum_metadata(aws_s3_object, part)
      part.ok!
    end
  end

  private

  # NOTE: no checksum computation is happening here (neither on our side, nor on AWS's).  we're just comparing
  # the checksum we have stored with the checksum we asked AWS to store.  we really don't expect any drift, but
  # we're here, and it's a cheap check to do, and it'd be weird if they differed, so why not?
  # TODO: in a later work cycle, we'd like to spot check some cloud archives: that is, pull the zip down,
  # re-compute the checksum for the retrieved zip, and make sure it matches what we stored.
  def compare_checksum_metadata(aws_s3_object, part)
    replicated_checksum = aws_s3_object.metadata["checksum_md5"]
    if part.md5 == replicated_checksum
      part.update(last_checksum_validation: Time.zone.now)
      true
    else
      results.add_result(
        AuditResults::ZIP_PART_CHECKSUM_MISMATCH,
        endpoint_name: part.zipped_moab_version.zip_endpoint.endpoint_name,
        s3_key: part.s3_key,
        md5: part.md5,
        replicated_checksum: replicated_checksum,
        bucket_name: bucket_name
      )
      part.update(status: 'replicated_checksum_mismatch', last_checksum_validation: Time.zone.now)
      false
    end
  end

  def check_existence(aws_s3_object, part)
    if aws_s3_object.exists?
      part.update(last_existence_check: Time.zone.now)
      true
    else
      results.add_result(
        AuditResults::ZIP_PART_NOT_FOUND,
        endpoint_name: part.zipped_moab_version.zip_endpoint.endpoint_name,
        s3_key: part.s3_key,
        bucket_name: bucket_name
      )
      part.update(status: 'not_found', last_existence_check: Time.zone.now)
      false
    end
  end
end
