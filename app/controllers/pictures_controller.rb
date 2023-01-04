class PicturesController < ApplicationController
  before_action :set_picture, only: %i[ show edit update destroy ]

  def index
    @pictures = Picture.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @picture = Picture.new
  end

  def edit
  end

  def create
    @picture = Picture.new(file: process_image(picture_params[:file]), name: picture_params[:name])

    if @picture.save
      redirect_to @picture, notice: "Picture was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @picture.update(picture_params)
      redirect_to @picture, notice: "Picture was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @picture.destroy
    redirect_to pictures_url, notice: "Picture was successfully destroyed."
  end

  private

  # calls resize_and_convert_before_storage(file) to downsize the image and convert to webp
  # replaces the original file with the new one
  # update filename and content_type to indicate the new file type "image/webp"
  # does not overwrite params
  def process_image(file)
    # TODO: validate uploaded file first!
    # is image?
    # Pictures::ALLOWED_CONTENT_TYPES
    # file size MByte (min..max)
    # file size Pixels (min..max)
    # landscape vs portrait or square?

    new_file = file.dup

    original_extension = File.extname(file.tempfile)
    updated_filename = file.original_filename.gsub(/(#{original_extension})$/, ".webp")

    new_file.original_filename = updated_filename
    new_file.content_type = "image/webp"
    new_file.tempfile = resize_and_convert_before_storage(file)

    new_file
  end

  # NOTE
  # resizes (downsizes) uploaded image to max of 4000x3000 pixels
  # converts to webp
  # does not (yet) strips EXIF data (e.g. GPS coordinates, date/time, camera model, dimensions, etc.)
  # sets quality to 90%
  # and only then the file is saved to disk
  # inspired by: https://vitobotta.com/2020/09/24/resize-and-optimise-images-on-upload-with-activestorage/
  #
  def resize_and_convert_before_storage(file)
    # TODO: check file size in pixels and fail when too small? e.g. less than 800x600 pixels
    # TODO: check conversion to WebP for all images - lossless for PNG and GIF, lossy for JPEG and TIFF ?
    #       or at least keep transparency for PNGs and GIFs? (but no animated GIFs)
    # TODO: only replace when downsized is smaller than original ?! Would need checks on pixel size as well as file size.

    ImageProcessing::Vips.source(file.tempfile).resize_to_limit(4000, 3000).convert("webp").saver(quality: 90).call!
  end

  def set_picture
    @picture = Picture.find(params[:id])
  end

  # switch to dry-validation / dry-contract
  def picture_params
    params.require(:picture).permit(:name, :file)
  end
end
