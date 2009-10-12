module Paperclip
  class Storage
    class Filesystem < Storage
      def write(path, file)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w" ) do |f|
          file.rewind
          f.write(file.read)
        end
      end

      def delete(path)
        File.delete(path)
      end

      def rename(src, dst)
        if src != dst
          write(dst, File.new(src))
          delete(src)
        end
      end
    end
  end
end
