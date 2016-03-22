# Action button helpers, i.e. to easily create a 'Show User' button
module ActionsHelper
  def view_button(object, link_path = object)
    link_to t('shared.actions.with_obj.view',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            class: 'btn btn-default'
  end

  def view_all_button(object)
    link_to t('shared.actions.with_obj.view_all',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 999)),
            url_for(action: :index, controller: object.model_name.plural),
            class: 'btn btn-default'
  end

  def new_button(model_class)
    link_to t('shared.actions.with_obj.new',
              obj: t("activerecord.models.#{model_class.model_name.singular}",
                     count: 1)),
            url_for(action: :new, controller: model_class.model_name.plural),
            class: 'btn btn-primary'
  end

  def edit_button(object, link_path = [:edit, object])
    link_to t('shared.actions.with_obj.edit',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            class: 'btn btn-default'
  end

  def destroy_button(object, link_path = object)
    link_to t('shared.actions.with_obj.destroy',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            method: :delete,
            data: { confirm: t('shared.prompts.confirm') },
            class: 'btn btn-danger'
  end
end
