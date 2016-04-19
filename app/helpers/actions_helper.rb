# Action button helpers, i.e. to easily create a 'Show User' button
module ActionsHelper
  def view_button(object, link_path = object)
    link_to t('shared.actions.with_obj.view',
              obj: t("mongoid.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            class: 'btn btn-default'
  end

  def view_all_button(object)
    link_to t('shared.actions.with_obj.view_all',
              obj: t("mongoid.models.#{object.model_name.singular}",
                     count: 999)),
            url_for(action: :index, controller: object.model_name.plural),
            class: 'btn btn-default'
  end

  def new_button(model_class)
    link_to t('shared.actions.with_obj.new',
              obj: t("mongoid.models.#{model_class.model_name.singular}",
                     count: 1)),
            url_for(action: :new, controller: model_class.model_name.plural),
            class: 'btn btn-primary'
  end

  def edit_button(object, link_path = [:edit, object])
    link_to t('shared.actions.with_obj.edit',
              obj: t("mongoid.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            class: 'btn btn-default'
  end

  def destroy_button(object, link_path = object)
    link_to t('shared.actions.with_obj.destroy',
              obj: t("mongoid.models.#{object.model_name.singular}",
                     count: 1)),
            link_path,
            method: :delete,
            data: { confirm: t('shared.prompts.confirm') },
            class: 'btn btn-danger'
  end

  # def link_to_edit(obj, pre_path = [], image = true)
  #   if image
  #     text = '<span class="glyphicon glyphicon-edit" aria-hidden="true"></span>'.html_safe
  #   else
  #     text = t('shared.actions.with_obj.destroy', obj: t("mongoid.models.#{obj.model_name.singular}", count: 1))
  #   end
  #   link_to text, [:edit] + pre_path + [obj], :title => t('helpers.links.edit'), :class => 'btn btn-warning'
  # end

  # def link_to_destroy(obj, pre_path = [], image = true)
  #   if image
  #     text = '<span class="glyphicon glyphicon-remove" aria-hidden="true"></span>'.html_safe
  #   else
  #     text = t('shared.actions.with_obj.edit', obj: t("mongoid.models.#{obj.model_name.singular}", count: 1))
  #   end
  #   link_to text, pre_path + [obj], :method => 'delete', :data => { :confirm => I18n.t("helpers.links.confirm") },
  #     :title => t('helpers.links.destroy'), :class => 'btn btn-danger'
  # end
  # def link_it(obj, pre_path = [], text = "", title = "")
  #   link_to text, pre_path + [obj], :title => title, :class => 'btn btn-info'
  # end

  def links_for(obj, path = nil, actions = [])
    model_key = obj.model_name.singular
    model_name = t("mongoid.models.#{model_key}", count: 1)
    links = ""
    actions.each { |a|
      if a == :pre
        text = t("mongoid.models.#{path.to_s}", count: 1)
        links += link_to text, [path], title: text
      elsif a == :view_all
        text = t('shared.actions.view_all', obj: model_name )
        links += link_to text, [path] + [obj.class], class: 'btn btn-default', title: text
      elsif ["new", "view", "edit", "destroy"].include?(a.to_s)
        text = t("shared.actions.#{a}", obj: model_name )
        links += link_to text, [:new, path, model_key], :title => text, :class => 'btn btn-primary' if a == :new
        links += link_to text, [path, obj], :title => text, :class => 'btn btn-info' if a == :view
        links += link_to text, [:edit, path, obj], :title => text, :class => 'btn btn-warning' if a == :edit
        links += link_to text, [path, obj], :method => 'delete', :data => { :confirm =>  t('shared.prompts.confirm') },
          :title => text, :class => 'btn btn-danger' if a == :destroy
      end
    }
    links.html_safe
  end
end

# <%= link_to t('.new', :default => t("helpers.links.new")),
#               new_polymorphic_path([:admin, model_class]) ,
#               :class => 'btn btn-primary' %>


 #  <%= link_to t('helpers.links.admin'), admin_path, :class => 'btn btn-default' %>
 #    <%= link_to t('.back', :default => t("helpers.links.back")),
 #              polymorphic_path([:admin, model_class]), :class => 'btn btn-default'  %>
 # <%= link_to polymorphic_path([:admin, item]),
 #              :title => t('helpers.links.view'),
 #              :class => 'btn btn-info' do %>
 #              <span class="glyphicon glyphicon-eye-open" aria-hidden="true"></span>
 #            <% end %>


