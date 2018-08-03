# Regular ruby class, not ActiveRecord
# Logic around our Zip Storage (cache) directory
class ZipStorage
  class << self
    # @return [Pathname]
    def path
      @path ||= Pathname.new(Settings.zip_storage)
    end
    alias zip_storage path
  end

 # find /sdr-transfers -name *.zip -mtime +30 -ls
end
