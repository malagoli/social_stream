class Site::Client < Site
  validates_presence_of :url, :callback_url, :secret

  before_validation :set_secret,
                    on: :create

  after_create :set_manager

  scope :managed_by, lambda { |actor|
    select("DISTINCT sites.*").
      joins(actor: :sent_permissions).
      merge(Contact.received_by(actor)).
      merge(Permission.where(action: 'manage', object: nil))
  }

  %w{ url callback_url secret }.each do |m|
    define_method m do
      config[m]
    end

    define_method "#{ m }=" do |arg|
      config[m] = arg
    end
  end

  def to_param
    id
  end

  # Generate a new OAuth secret for this site client
  def refresh_secret!
    set_secret
    save!
  end

  private

  def set_secret
    self.secret = SecureRandom.hex(64)
  end

  def set_manager
    c = sent_contacts.create! receiver_id: author.id,
                              user_author: author

    c.relation_ids = [ ::Relation::Manager.instance.id ]
  end
end
