module Paperclip
  class Processor
    # Handles thumbnailing images that are uploaded.
    class Thumbnail < Processor
      attr_accessor :scale_geometry, :crop_geometry, :source_geometry, :source_options, :destination_options
      attr_accessor :input, :output

      def initialize(file, options = {}, attachment = nil)
        super
        @input               = file
        @source_options      = options[:source_options]
        @destination_options = options[:destination_options]

        target_geometry      = Geometry.parse options[:geometry]
        @crop                = target_geometry.modifier == "#"

        if @crop
          @source_geometry = Geometry.from_file(file)
          @scale_geometry, @crop_geometry = @source_geometry.transformation_to(target_geometry, @crop)
        else
          @scale_geometry = target_geometry
        end
      end

      def make
        @output = Tempfile.new(File.basename(input.path))
        Paperclip.run("convert", command)
        @output
      end

      def command
        %["#{input.path}" #{transformation} "#{output.path}"]
      end

      def transformation
        command = []
        command << source_options if source_options
        command << %[-resize "#{scale_geometry}"]
        command << %[-crop "#{crop_geometry}" +repage] if crop_geometry
        command << destination_options if destination_options
        command.join(" ")
      end
    end
  end
end
