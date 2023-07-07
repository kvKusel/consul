module ProjektLabelActions
  extend ActiveSupport::Concern
  include Translatable

  included do
    respond_to :js

    before_action :set_projekt_phase, :set_namespace
    load_and_authorize_resource only: %i[edit update destroy]
  end

  def new
    @projekt_label = @projekt_phase.projekt_labels.new
    authorize! :new, @projekt_label

    render "custom/admin/projekt_labels/new"
  end

  def create
    @projekt_label = ProjektLabel.new(projekt_label_params)
    @projekt_label.projekt_phase = @projekt_phase
    authorize! :create, @projekt_label

    if @projekt_label.save
      redirect_to polymorphic_path([@namespace, @projekt_phase], action: :projekt_labels)
    else
      render :new
    end
  end

  def edit
    authorize! :edit, @projekt_label
    render "custom/admin/projekt_labels/edit"
  end

  def update
    authorize! :update, @projekt_label

    if @projekt_label.update(projekt_label_params)
      redirect_to polymorphic_path([@namespace, @projekt_phase], action: :projekt_labels)
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @projekt_label

    @projekt_label.destroy!
    redirect_to polymorphic_path([@namespace, @projekt_phase], action: :projekt_labels),
                notice: t("custom.admin.projekt.label.destroy.success")
  end

  private

    def set_projekt_phase
      @projekt_phase = ProjektPhase.find(params[:projekt_phase_id])
    end

    def set_namespace
      @namespace = params[:controller].split("/").first.to_sym
    end

    def projekt_label_params
      params.require(:projekt_label).permit(:color, :icon, :projekt_id, translation_params(ProjektLabel))
    end
end
