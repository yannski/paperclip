module Paperclip
  class Processor
    # Handles thumbnailing images that are uploaded.
    class Thumbnail < Processor
      attr_accessor :scale_geometry, :crop_geometry, :source_geometry, :source_options, :destination_options

      def initialize file, options = {}, attachment = nil
        super
        @file                = file
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
      end

      def transformation
        command = []
        command << source_options                      if source_options
        command << %[-resize "#{scale_geometry}"]
        command << %[-crop "#{crop_geometry}" +repage] if crop_geometry
        command << destination_options                 if destination_options
        command.join(" ")
      end
    end
  end
end
