class PicturesController < ApplicationController
  skip_before_action :authenticate, only: %i[index show] # allow everyone to see the pictures
  before_action :set_picture, only: %i[show edit update destroy]

  def index
    @pictures = Picture.order(created_at: :desc)
  end

  def show
  end

  def new
    @picture = Picture.new(team: current_team, creator: current_user)
  end

  def edit
  end

  def create
    unless picture_params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      raise CustomError.new("File not valid", status: 422, code: :unprocessable_entity)
    end

    @picture = Picture.new(
      file: ImageUploadConversionService.call(file: picture_params[:file], name: picture_params[:name]),
      name: picture_params[:name], # looks redundant, but image filename is parameterized
      date: picture_params[:date],
      team: current_team,
      creator: current_user
    )

    if @picture.save
      redirect_to @picture, notice: "Picture was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @picture.update(picture_params.merge(updater: current_user))
      redirect_to @picture, notice: "Picture was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @picture.destroy!

    redirect_to pictures_url, notice: "Picture was successfully destroyed."
  end

  private

  def set_picture
    @picture = Picture.urlsafe_find(params[:id])
  end

  # switch to dry-validation / dry-contract
  def picture_params
    params.require(:picture).permit(:file, :date, :name)
  end
end
