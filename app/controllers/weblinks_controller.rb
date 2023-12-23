class WeblinksController < ApplicationController
  before_action :set_weblink, only: %i[show edit update destroy]

  # GET /weblinks
  def index
    @weblinks = Weblink.all
  end

  # GET /weblinks/1
  def show
  end

  # GET /weblinks/new
  def new
    @weblink = Weblink.new
  end

  # GET /weblinks/1/edit
  def edit
  end

  # POST /weblinks
  def create
    @weblink = Weblink.new(weblink_params)

    if @weblink.save
      redirect_to @weblink, notice: "Weblink was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /weblinks/1
  def update
    if @weblink.update(weblink_params)
      redirect_to @weblink, notice: "Weblink was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /weblinks/1
  def destroy
    @weblink.destroy!
    redirect_to weblinks_url, notice: "Weblink was successfully destroyed.", status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_weblink
    @weblink = Weblink.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def weblink_params
    params.require(:weblink).permit(:url, :name, :description, :preview_snippet)
  end
end
