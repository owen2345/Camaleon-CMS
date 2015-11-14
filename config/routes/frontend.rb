Rails.application.routes.draw do
  scope PluginRoutes.system_info["relative_url_root"], as: "cama" do
    scope "(:locale)", locale: /#{PluginRoutes.all_locales}/, :defaults => {  } do
      root 'camaleon_cms/frontend#index'

      controller "camaleon_cms/frontend" do
        PluginRoutes.all_locales.split("|").each do |_l|
          get "#{I18n.t("routes.group", default: "group", locale: _l)}/:post_type_id-:title" => :post_type, as: "post_type_#{_l}", constraints: {post_type_id: /[0-9]+/}
          get "#{I18n.t("routes.group", default: "group", locale: _l)}/:post_type_id-:title/:slug" => :post, as: "post_of_post_type_#{_l}", constraints: {post_type_id: /[0-9]+/}

          get "#{I18n.t("routes.category", default: "category", locale: _l)}/:category_id-:title" => :category, as: "category_#{_l}", constraints: {category_id: /[0-9]+/}
          get "#{I18n.t("routes.category", default: "category", locale: _l)}/:category_id-:title/:slug" => :post, as: "post_of_category_#{_l}", constraints: {category_id: /[0-9]+/}
          get ":post_type_title/#{I18n.t("routes.category", default: "category", locale: _l)}/:category_id-:title/:slug" => :post, as: "post_of_category_post_type_#{_l}", constraints:{ post_type_title: /(?!(#{PluginRoutes.all_locales}))[\w]+/, category_id: /[0-9]+/ }

          get "#{I18n.t("routes.tag", default: "tag", locale: _l)}/:post_tag_id-:title" => :post_tag, as: "post_tag_#{_l}", constraints: {post_tag_id: /[0-9]+/}
          get "#{I18n.t("routes.tag", default: "tag", locale: _l)}/:post_tag_id-:title/:slug" => :post, as: "post_of_tag_#{_l}", constraints: {post_tag_id: /[0-9]+/}

          get "#{I18n.t("routes.profile", default: "profile", locale: _l)}/:user_id-:user_name" => :profile, constraints: {user_id: /[0-9]+/}, as: "profile_#{_l}"
          get "#{I18n.t("routes.search", default: "search", locale: _l)}" => :search, as: "search_#{_l}"
        end

        get "profile/:user_id-:user_name" => :profile, as: :profile, constraints: {user_id: /[0-9]+/}
        get 'search' => :search, as: :search
        get ':post_type_title/:slug' => :post, as: :post_of_posttype, constraints:{ post_type_title: /(?!(#{PluginRoutes.all_locales}))[\w]+/ }

        post 'save_comment/:post_id' => :save_comment, as: :save_comment
        post 'save_form' => :save_form, as: :save_form

        # sitemap
        get "sitemap" => :sitemap, as: :sitemap, defaults: { format: :xml }
        get "robots" => :robots, as: :robots, defaults: { format: :txt }
        get "rss", defaults: { format: "rss" }
        get "ajax"
      end

      get ":slug" => 'camaleon_cms/frontend#post', format: true, :as => :post1, defaults: { format: :html }, constraints: { slug: /(?!admin)[a-zA-Z0-9\._=\s\-]+/}
      get ":slug" => 'camaleon_cms/frontend#post', :as => :post, constraints: { slug: /(?!admin)[a-zA-Z0-9\._=\s\-]+/}
    end
  end

  scope PluginRoutes.system_info["relative_url_root"] do
    scope "(:locale)", locale: /#{PluginRoutes.all_locales}/, :defaults => {  } do
      instance_eval(PluginRoutes.load("front"))
    end
  end

end
