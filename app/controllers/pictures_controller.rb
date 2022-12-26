class PicturesController < ApplicationController
  before_action :set_picture, only: %i[ show edit update destroy ]

  # GET /pictures
  def index
    @pictures = Picture.all
  end

  # GET /pictures/1
  def show
  end

  # GET /pictures/new
  def new
    @picture = Picture.new
  end

  # GET /pictures/1/edit
  def edit
  end

  # POST /pictures
  def create
    @picture = Picture.new(picture_params)

    if @picture.save
      redirect_to @picture, notice: "Picture was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /pictures/1
  def update
    if @picture.update(picture_params)
      redirect_to @picture, notice: "Picture was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /pictures/1
  def destroy
    @picture.destroy
    redirect_to pictures_url, notice: "Picture was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_picture
      @picture = Picture.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def picture_params
      params.require(:picture).permit(:name)
    end
end
