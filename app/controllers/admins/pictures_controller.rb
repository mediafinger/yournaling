module Admins
  class PicturesController < AdminController
    def index
      @pictures = Picture.all
    end

    def show
      @picture = Picture.urlsafe_find!(params[:id])
    end

    def new
      @picture = Picture.new(team: current_team)
    end

    def edit
      @picture = Picture.urlsafe_find!(params[:id])
    end

    def create
      unless picture_params[:file].is_a?(ActionDispatch::Http::UploadedFile)
        raise CustomError.new("File not valid", status: 422, code: :unprocessable_content)
      end

      # IDEA
      # upload AND validate original picture
      # store original picture if valid
      # in a background job, create an XL / 4k variant with up to 4000x4000 pixels
      # and replace the original file attachment with the webp 4k variant
      # rely on dependent: :purge_later to delete the original picture
      # the variants can be cropped to fit the desired aspect ratio for all preview images on the website
      # create the other variants (consider portrait, square, landscape orginal picture aspect ratios)
      #
      @picture = Picture.new(
        file: ImageUploadConversionService.call(file: picture_params[:file], name: picture_params[:name]),
        name: picture_params[:name], # looks redundant, but image filename is parameterized
        date: picture_params[:date],
        team_id: picture_params[:team_id]
      )

      Picture.create_with_history(record: @picture, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @picture.persisted?
        redirect_to admin_picture_url(@picture), notice: "Picture was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @picture = Picture.urlsafe_find!(params[:id])
      @picture.assign_attributes(picture_params)

      Picture.update_with_history(record: @picture, history_params: { team: nil, user: current_user, done_by_admin: true })

      if @picture.changed? # == picture still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to admin_picture_url(@picture), notice: "Picture was successfully updated."
      end
    end

    def destroy
      @picture = Picture.urlsafe_find!(params[:id])

      Picture.destroy_with_history(record: @picture, history_params: { team: nil, user: current_user, done_by_admin: true })

      redirect_to admin_pictures_url, notice: "Picture was successfully destroyed."
    end

    private

    # switch to dry-validation / dry-contract
    def picture_params
      params.expect(picture: %i[file date name team_id])
    end
  end
end
