require_dependency Rails.root.join("app", "controllers", "proposals_controller").to_s

class ProposalsController
  include ProposalsHelper
  include ProjektControllerHelper
  include Takeable
  include ProjektLabelAttributes

  before_action :set_projekts_for_selector, only: [:new, :edit, :create, :update]

  def index_customization
    if params[:order].nil?
      @current_order = Setting["selectable_setting.proposals.default_order"]
    end
    @resource_name = "proposal"

    if params[:filter_projekt_ids]
      @selected_projekts_ids = params[:filter_projekt_ids].select { |id| Projekt.find_by(id: id).present? }
      selected_parent_projekt_id = get_highest_unique_parent_projekt_id(@selected_projekts_ids)
      @selected_parent_projekt = Projekt.find_by(id: selected_parent_projekt_id)
    end

    related_projekt_ids = @resources.joins(projekt_phase: :projekt).pluck("projekts.id").uniq
    related_projekts = Projekt.where(id: related_projekt_ids)

    @geozones = Geozone.all
    @selected_geozone_affiliation = params[:geozone_affiliation] || 'all_resources'
    @affiliated_geozones = (params[:affiliated_geozones] || '').split(',').map(&:to_i)
    @selected_geozone_restriction = params[:geozone_restriction] || 'no_restriction'
    @restricted_geozones = (params[:restricted_geozones] || '').split(',').map(&:to_i)

    discard_draft
    discard_archived
    load_retired
    load_selected
    load_featured
    remove_archived_from_order_links

    @scoped_projekt_ids = Proposal.scoped_projekt_ids_for_index(current_user)

    @top_level_active_projekts = Projekt.top_level.current.where(id: @scoped_projekt_ids)
    @top_level_archived_projekts = Projekt.top_level.expired.where(id: @scoped_projekt_ids)

    @categories = Tag.category.joins(:taggings)
      .where(taggings: { taggable_type: "Projekt", taggable_id: related_projekt_ids }).order(:name).uniq

    if params[:sdg_goals].present?
      sdg_goal_ids = SDG::Goal.where(code: params[:sdg_goals].split(",")).ids
      @sdg_targets = SDG::Target.where(goal_id: sdg_goal_ids).joins(:relations)
        .where(sdg_relations: { relatable_type: "Projekt", relatable_id: related_projekt_ids })
    end

    unless params[:search].present?
      take_by_my_posts
      take_by_tag_names(related_projekts)
      take_by_sdgs(related_projekts)
      take_by_geozone_affiliations
      take_by_geozone_restrictions
      take_by_projekts(@scoped_projekt_ids)
    end

    @proposals_coordinates = all_proposal_map_locations(@resources)
    @proposals = @resources.page(params[:page]).send("sort_by_#{@current_order}")
    # @selected_tags = all_selected_tags

    if Setting.new_design_enabled?
      render :index_new
    else
      render :index
    end
  end

  def new
    redirect_to proposals_path if proposal_limit_exceeded?(current_user)
    redirect_to proposals_path if Projekt.top_level.selectable_in_selector("proposals", current_user).empty?

    if params[:projekt_phase_id].present?
      @projekt_phase = ProjektPhase::ProposalPhase.find(params[:projekt_phase_id])
      @projekt = @projekt_phase.projekt
    end

    @resource = resource_model.new
    set_geozone
    set_resource_instance
    @selected_projekt = Projekt.find(params[:projekt_id]) if params[:projekt_id]
  end

  def edit
    @selected_projekt = @proposal&.projekt_phase&.projekt

    params[:projekt_phase_id] = @proposal&.projekt_phase&.id
    params[:projekt_id] = @selected_projekt&.id
  end

  def create
    @proposal = Proposal.new(proposal_params.merge(author: current_user))

    if params[:save_draft].present? && @proposal.save
      redirect_to user_path(@proposal.author, filter: "proposals"), notice: I18n.t("flash.actions.create.proposal")

    elsif @proposal.save
      @proposal.publish

      if @proposal.projekt_phase.active?
        if @proposal.projekt_phase.projekt.overview_page?
          redirect_to projekts_path(
            anchor: "filter-subnav",
            selected_phase_id: @proposal.projekt_phase.id,
            order: params[:order]
          ), notice: t("proposals.notice.published")
        else
          redirect_to page_path(
            @proposal.projekt_phase.projekt.page.slug,
            anchor: "filter-subnav",
            selected_phase_id: @proposal.projekt_phase.id,
            order: params[:order]
          ), notice: t("proposals.notice.published")
        end
      else
        if @proposal.projekt_phase.projekt.overview_page?
          redirect_to projekts_path(
            anchor: "filter-subnav",
            selected_phase_id: @proposal.projekt_phase.id,
            order: params[:order]
          ), notice: t("proposals.notice.published")
        else
          redirect_to proposals_path(
            resources_order: params[:order]
          ), notice: t("proposals.notice.published")
        end
      end
    else
      @selected_projekt = @proposal&.projekt_phase&.projekt
      params[:projekt_phase_id] = @proposal&.projekt_phase&.id
      params[:projekt_id] = @selected_projekt&.id
      render :new
    end
  end

  def publish
    @proposal.publish

    if @proposal.projekt_phase.active?
      redirect_to page_path(
        @proposal.projekt_phase.projekt.page.slug,
        anchor: "filter-subnav",
        selected_phase_id: @proposal.projekt_phase.id,
        order: "created_at"), notice: t("proposals.notice.published")
    else
      redirect_to proposals_path(order: "created_at"), notice: t("proposals.notice.published")
    end
  end

  def show
    super
    @projekt = @proposal.projekt_phase.projekt
    @notifications = @proposal.notifications
    @notifications = @proposal.notifications.not_moderated
    @related_contents = Kaminari.paginate_array(@proposal.relationed_contents)
                                .page(params[:page]).per(5)

    if request.path != proposal_path(@proposal)
      redirect_to proposal_path(@proposal), status: :moved_permanently

    elsif !@projekt.visible_for?(current_user)
      @individual_group_value_names = @projekt.individual_group_values.pluck(:name)
      render "custom/pages/forbidden", layout: false

    end

    @affiliated_geozones = (params[:affiliated_geozones] || '').split(',').map(&:to_i)
    @restricted_geozones = (params[:restricted_geozones] || '').split(',').map(&:to_i)

    if Setting.new_design_enabled?
      render :show_new
    else
      render :show
    end
  end

  def unvote
    @follow = Follow.find_by(user: current_user, followable: @proposal)
    @follow.destroy if @follow
    @proposal.unvote_by(current_user)
  end

  def created
    @resource_name = 'proposal'
    @affiliated_geozones = []
    @restricted_geozones = []

  end

  def flag
    Flag.flag(current_user, @proposal)
    redirect_to @proposal
  end

  def unflag
    Flag.unflag(current_user, @proposal)
    redirect_to @proposal
  end

  private

    def proposal_params
      attributes = [:id, :video_url, :responsible_name, :tag_list, :on_behalf_of,
                    :geozone_id, :projekt_id, :projekt_phase_id, :related_sdg_list,
                    :terms_of_service, :terms_data_storage, :terms_data_protection, :terms_general, :resource_terms,
                    :sentiment_id,
                    projekt_label_ids: [],
                    image_attributes: image_attributes,
                    documents_attributes: [:id, :title, :attachment, :cached_attachment,
                                           :user_id, :_destroy],
                    map_location_attributes: map_location_attributes]
      translations_attributes = translation_params(Proposal, except: :retired_explanation)
      params.require(:proposal).permit(attributes, translations_attributes)
    end

    def proposal_limit_exceeded?(user)
      user.proposals.where(retired_at: nil).count >= Setting['extended_option.proposals.max_active_proposals_per_user'].to_i
    end
end
