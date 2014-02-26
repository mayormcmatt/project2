class FuncheapsController < ApplicationController
    def create
        date_params = params.require(:itinerary).permit(:date)
        a = date_params[:date].split("/")
        search_date = Date.new(a[2].to_i, a[0].to_i, a[1].to_i)
        FuncheapResult.all.each do |record|
            record.destroy
        end

        Funcheap.all.each do |f|
            if f.date != nil || f.date == "" && search_date == Date.parse(f.date)
                FuncheapResult.create(
                    name: f.name,
                    full_address: f.full_address,
                    date: f.date,
                    latitude: f.latitude,
                    longitude: f.longitude
                    )
            end
        end
        redirect_to wingman_path
    end

    def perform_scrape
        agent = Mechanize.new
        #Mechanize scrapes site
        # event_date = params[:date]
        page_num = 1
        until page_num == 3
            url = "http://sf.funcheap.com/events/page/#{page_num}"
            list = agent.get(url) #list of links on target page
            page_links = list.search(".title2 a") #gets all links with CSS selector ".title2 a"
            page_links.each do |url| #start loop over page_links
                result_page = Mechanize::Page::Link.new(url, agent, list).click #clicks all links one-by-one
                name = result_page.search('.title').text.partition('|').first.strip #display title by CSS selector
                full_address = result_page.search("//b[contains(., 'Address')]/..").text.partition(':').last.strip #pull address by xpath
                event_date = result_page.search("#stats .left > a").text
                # event_desc = result_page.search(".clearfloat > p").text.strip
                # Save to the model
                unless full_address == nil #address might be empty ""; check that out later
                    event = Funcheap.find_or_create_by(name: name)
                    event.full_address = full_address
                    event.date = event_date
                    # event.description = event_desc
                    event.save
                end
            end
            page_num += 1
        end
        redirect_to "/"
    end
end
