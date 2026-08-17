module CurrentTeams
  class PicturesController < AppCurrentTeamController
    skip_before_action :authenticate, only: %i[index show] # allow everyone to see the pictures

    def index
      authorize! current_user, to: :index?, with: PicturePolicy

      pictures = authorized_scope(Picture.all, type: :relation, as: :current_team_scope)

      @pictures = pictures
    end

    def show
      @picture = Picture.urlsafe_find!(params[:id])
      authorize! @picture
    end

    def new
      @picture = Picture.new(team: current_team)
      authorize! @picture
    end

    def edit
      @picture = Picture.urlsafe_find!(params[:id])
      authorize! @picture
    end

    def create
      @picture = Picture.new(team: current_team)
      authorize! @picture

      unless picture_params[:file].is_a?(ActionDispatch::Http::UploadedFile)
        respond_to do |format|
          format.html { raise CustomError.new("File not valid", status: 422, code: :unprocessable_content) }
          format.json { render json: { errors: ["Please select an image file to upload"] }, status: :unprocessable_content }
        end
        return
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
      @picture.file = ImageUploadConversionService.call(file: picture_params[:file], name: picture_params[:name])
      @picture.name = picture_params[:name]
      @picture.date = picture_params[:date]

      Picture.create_with_event(record: @picture, event_params: { team: current_team, user: current_user })

      respond_to do |format|
        if @picture.persisted?
          thumb_url = helpers.rails_representation_path(@picture.thumbnail) if @picture.thumbnail
          format.html { redirect_to current_team_picture_url(@picture), notice: "Picture was successfully created." }
          format.json do
            render json: { id: @picture.id, name: @picture.name, thumb_url: thumb_url, type: "picture" }, status: :created
          end
        else
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: { errors: @picture.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    def update
      @picture = Picture.urlsafe_find!(params[:id])
      authorize! @picture
      @picture.assign_attributes(picture_params)

      Picture.update_with_event(record: @picture, event_params: { team: current_team, user: current_user })

      if @picture.changed? # == picture still dirty, not saved
        render :edit, status: :unprocessable_content
      else
        redirect_to current_team_picture_url(@picture), notice: "Picture was successfully updated."
      end
    end

    def destroy
      @picture = Picture.urlsafe_find!(params[:id])
      authorize! @picture

      if @picture.memories.exists? || @picture.chronicle_entries.exists?
        redirect_to edit_current_team_picture_url(@picture),
          alert: "Picture cannot be destroyed because it is still referenced by other content."
      else
        Picture.destroy_with_event(record: @picture, event_params: { team: current_team, user: current_user })
        redirect_to current_team_pictures_url, notice: "Picture was successfully destroyed."
      end
    end

    private

    # switch to dry-validation / dry-contract
    def picture_params
      params.expect(picture: %i[file date name])
    end
  end
end
