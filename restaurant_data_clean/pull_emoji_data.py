from selenium import webdriver
import pandas as pd
import os


# Url to go to to search for emoji ratings
base = "http://www.kingcounty.gov/depts/health/environmental-health" +\ 
    "/food-safety/inspection-system/search.aspx#/"
# start up the webdriver
driver = webdriver.Firefox()
# this lets webdriver wait 10 seconds
driver.implicitly_wait(10) 
# go to the food web page
driver.get(base)

# list of restuarants to search for
# use xpath to find the button to press when text is entered
btnsearch = "(//button[@aria-label='Search restaurant inspections'])[1]"
# xpath to find orevious button
btnprev = "(//a[text()='Previous'])[1]"
# xpath to find next button
btnnext = "(//a[text()='Next'])[1]"
# find the next class and fail when it doesnt denoting the end maybe
nextclass = "//li[@class='next']"
# use xpath to find the emoji image after search is made
imgsearch = "div/div/div/p/img[@class='img-rounded']"
results = {x: list() for x in ["name", "status", "address"]}


for i in range(1000):
    # get the results
    rlist = driver.find_element_by_id('restaurant-list')
    # get important data
    rez = rlist.find_elements_by_xpath("div/div/div/p/img[@class='img-rounded']")
    status = [x.get_attribute("src").split("/")[-1].split("_")[0] for x in rez]
    rez = rlist.find_elements_by_xpath("div/div/div/p/strong")
    name = [x.text for x in rez]
    rez = rlist.find_elements_by_xpath("div/div/div/p")
    addressplus = [x.text for x in rez if "\n" in x.text]
    address = [ '\n'.join(x.split("\n")[1:]) for x in addressplus]
    # append data to list
    results["name"] += name
    results["address"] += address
    results["status"] += status
    try:
        driver.find_element_by_xpath(nextclass)
        driver.find_element_by_xpath(btnnext).click()
        continue
    except:
        break


# save the results
DF = pd.DataFrame(results)
f_ = os.path.join(os.path.expanduser("~"), "Downloads", "emojiscores.csv")
DF.to_csv(f_, index=False, encoding="utf-8")
