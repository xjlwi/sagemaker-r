import streamlit as st
import numpy as np
import pandas as pd
import streamlit as st
import psycopg2
from personal_info import print_pulse
from personal_info import destions
import numbers
import warnings

warnings.filterwarnings("ignore")

def skills():
    list_of_skills = ['Exploratory Data Analysis', 
                      'Data Visualisation (Power BI)',
                      'Dashboarding (R/Python)',
                      'Data Pipeline/Data Automation',
                      'Data collection (API/PI-systems)',
                      'Supervised Machine Learning',
                      'Unsupervised Machine Learning',
                      'Time Series',
                      'Databases SQL/NoSQL', 
                      'Data Science Enablers (deployment, Containerisation docker, Azure/AWS cloud)',
                      'Feature Engineering',
                      'Optimisation',
                      'System Simulation',
                      'Natural Language Processing (NLP) & Text analytics',
                      'Image/Video Analytics',
                      'Audio Analytics/Speech Recognition',
                      'OTHER']
    return sorted(list_of_skills)

@st.
def app():
    st.title('Data Scientists Landing')

    ## Part 1: PERSONAL INFO ##
    form = st.form(key="annotation")
    QUESTIONS = destions()
    with form:
        cols = st.columns((1, 1))
        author = cols[0].date_input("Date of submission:")
        name = cols[1].selectbox("Name", ['Elaine Khoo', 'Siti Aisyah Dalilah Gazali', 'Crystal Lwi',\
            'Rajamani Sambasivam'])
        print_pulse()
        
        # Last 3-months experience, last 1-week experience
        q1 = st.multiselect(QUESTIONS['q1'], options= skills())
        q2 = st.multiselect(QUESTIONS['q2'], options= skills())
        
        q3 = st.number_input("Sample weight")
        st.write(q1)
        st.write(q3)
        # Areas of interest
        other_areas = st.multiselect(QUESTIONS['q3'], options= skills())
        st.form_submit_button(label="Next")
        
        if st.checkbox('Next'):
            cols = st.columns(len(other_areas))
            if len(other_areas) > 5:
                st.warning("Please make only 5 choices.")
            else:
                if 'OTHER' in other_areas:
                    cols = st.columns(len(other_areas) - 1)
                    other_areas.remove('OTHER')
                    ranks = np.array(range(1,len(other_areas) + 1))
                    
                    # initialise to store output
                    output_ranks = {}
                    for i, col in enumerate(cols):
                        rank = col.radio(f'Please rank {other_areas[i]}, \
                                        [1: most important, 5: least important]', ranks)
                        output_ranks = {other_areas[i]: rank}
                    
                    st.write('\n')
                    st.text_input("What other areas of Data Science that you are interested in?", key = 'Other_area_of_interest')
        

    if st.checkbox("Part 2: Your 💬"):
        left, right = st.columns(2)
        form = left.form("Placeholder")
        
        project_rotation = form.selectbox(
            QUESTIONS['q5'], 
            ['Yes', 'No', 'Maybe']
            )
        new_project_assignment = form.selectbox(
            QUESTIONS['q6'],
            ['Yes', 'No', 'Maybe']
        )
        
        form2 = right.form("Current Status")
        current_project = form2.multiselect(
            QUESTIONS['q7'],
            ['Aries', 'Raphael', 'STELLAR', 'Citizen Analytics', 'ALL']
        ),
        current_commitment = form2.slider(
            QUESTIONS['q8'], 
            0, 24, step = 1,
            value= (0,3)
            )
        
        submit = form.form_submit_button("Generate PDF")
        submit2 = form2.form_submit_button("Generate PDF")

    if st.checkbox("Part 3: Other feedback"):
        
        comment = st.text_area("Suggestions")