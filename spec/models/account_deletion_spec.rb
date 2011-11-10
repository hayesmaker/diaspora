#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe AccountDeletion do
  it 'assigns the diaspora_id from the person object' do
    a = AccountDeletion.new(:person => alice.person)
    a.diaspora_id.should == alice.person.diaspora_handle
  end

  it 'fires a resque job after creation'do
    Resque.should_receive(:enqueue).with(Jobs::DeleteAccount, anything)

    AccountDeletion.create(:person => alice.person)
  end

  describe "#perform!" do
    before do
      @ad = AccountDeletion.new(:person => alice.person)
    end
    it 'creates a deleter' do
      AccountDeleter.should_receive(:new).with(alice.person.diaspora_handle).and_return(stub(:perform! => true))
      @ad.perform!
    end
    
    it 'dispatches the account deletion if the user exists' do
      @ad.should_receive(:disparch)
      @ad.perform!
    end

    it 'does not dispatch an account deletion for non-local people' do
      @ad.should_not_receive(:disparch)
      @ad.perform!
    end
  end

  describe '#dispatch' do
    it "sends the account deletion xml" do
      
    end
  end

  describe "#subscribers" do
    it 'includes all the contacts' 
    it 'includes resharers'
  end
end
