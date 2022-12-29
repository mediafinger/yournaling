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
    @picture = Picture.new(picture_params)

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

  def set_picture
    @picture = Picture.find(params[:id])
  end

  # switch to dry-validation / dry-contract
  def picture_params
    params.require(:picture).permit(:name, :file)
  end
end
