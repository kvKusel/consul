class Admin::ProjektPhasesController < Admin::BaseController
  include ProjektPhaseActions

  def edit
    @registered_address_groupings = RegisteredAddress::Grouping.all
    @individual_groups = IndividualGroup.visible
    super
  end

  def update
    super
  end

  def order_phases
    @projekt = Projekt.find(params[:projekt_id])
    @projekt.projekt_phases.order_phases(params[:ordered_list])
    head :ok
  end

  private

    def namespace_projekt_phase_path(projekt, projekt_phase)
      admin_projekt_projekt_phase_path(projekt, projekt_phase)
    end

    def edit_namespace_projekt_path(projekt)
      if projekt.special?
        admin_projekts_path(anchor: "tab-projekts-overview-page")
      else
        edit_admin_projekt_path(projekt)
      end
    end
end
