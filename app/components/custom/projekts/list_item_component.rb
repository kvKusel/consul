# frozen_string_literal: true

class Projekts::ListItemComponent < ApplicationComponent
  attr_reader :projekt

  def initialize(projekt:, wide: false)
    @projekt = projekt
    @wide = wide
  end

  def component_attributes
    {
      resource: projekt,
      title: projekt.page.title,
      description: projekt.description,
      tags: projekt.tags.first(3),
      # start_date: projekt.total_duration_start,
      # end_date: projekt.total_duration_end,
      wide: @wide,
      url: projekt.page.url,
      card_image_url: card_image_url,
      horizontal_card_image_url: horizontal_card_image_url,
      # image_url: url_for(projekt.page&.image&.attachment&.variant(:medium)),
      id: projekt.id
    }
  end

  def card_image_url
    if image_variant(:card_thumb).present?
      image_variant(:card_thumb)
    elsif image_variant(:thumb_wider).present?
      image_variant(:thumb_wider)
    else
      # If new image not presenta fallback to old
      image_variant(:medium)
    end
  end

  def horizontal_card_image_url
    if image_variant(:horizontal_card_thumb).present?
      image_variant(:horizontal_card_thumb)
    elsif image_variant(:thumb_wider).present?
      image_variant(:thumb_wider)
    else
      # If new image not presenta fallback to old
      image_variant(:medium)
    end
  end

  def image_variant(variant)
    projekt.image&.variant(variant)
  end

  def date_formated
    base_formated_date = helpers.format_date_range(projekt.total_duration_start, projekt.total_duration_end)

    base_formated_date.presence || "Fortlaufendes Projekt"
  end

  def phase_icon_class(phase)
    case phase
    when ProjektPhase::CommentPhase
      "fa-comment-dots"
    when ProjektPhase::DebatePhase
      "fa-comments"
    when ProjektPhase::ProposalPhase
      "fa-lightbulb"
    when ProjektPhase::QuestionPhase
      "fa-poll-h"
    when ProjektPhase::BudgetPhase
      "fa-euro-sign"
    when ProjektPhase::VotingPhase
      "fa-vote-yea"
    when ProjektPhase::LegislationPhase
      "fa-file-word"
    when ProjektPhase::ArgumentPhase
      "fa-user-tie"
    when ProjektPhase::NewsfeedPhase
      "fa-newspaper"
    when ProjektPhase::MilestonePhase
      "fa-tasks"
    when ProjektPhase::EventPhase
      "fa-calendar-alt"
    when ProjektPhase::LivestreamPhase
      "fa-video"
    when ProjektPhase::ProjektNotificationPhase
      "fa-bell"
    end
  end
end
